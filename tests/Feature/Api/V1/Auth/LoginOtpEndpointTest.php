<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Data\Auth\IssuedEmailOtp;
use App\Enums\Auth\EmailVerificationPurpose;
use App\Mail\Auth\EmailOtpMail;
use App\Models\User;
use App\Services\Auth\EmailOtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class LoginOtpEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_otp_can_be_requested(): void
    {
        Mail::fake();

        User::factory()->create([
            'email' => 'login@example.com',
            'status' => User::STATUS_ACTIVE,
        ]);

        $response = $this->postJson(
            '/api/v1/auth/login/request-otp',
            [
                'email' => ' LOGIN@Example.com ',
                'locale' => 'en',
            ],
        );

        $response
            ->assertAccepted()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'data.expires_in_seconds',
                180,
            )
            ->assertJsonPath(
                'data.resend_after_seconds',
                60,
            )
            ->assertJsonStructure([
                'data' => [
                    'verification_id',
                ],
                'meta' => [
                    'request_id',
                ],
            ]);

        Mail::assertSent(
            EmailOtpMail::class,
            function (EmailOtpMail $mail): bool {
                return $mail->hasTo(
                    'login@example.com',
                )
                    && $mail->purpose
                        === EmailVerificationPurpose::Login;
            },
        );
    }

    public function test_existing_user_can_login_with_correct_otp(): void
    {
        $user = User::factory()->create([
            'email' => 'existing@example.com',
            'email_verified_at' => null,
            'preferred_locale' => 'en',
            'status' => User::STATUS_ACTIVE,
        ]);

        $issued = $this->issueLoginOtp(
            'existing@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/login/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'existing@example.com',
                locale: 'fr',
            ),
        );

        $response
            ->assertOk()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'message',
                'Signed in successfully.',
            )
            ->assertJsonPath(
                'data.user.id',
                $user->public_id,
            )
            ->assertJsonPath(
                'data.user.email',
                'existing@example.com',
            )
            ->assertJsonPath(
                'data.user.email_verified',
                true,
            )
            ->assertJsonPath(
                'data.user.preferred_locale',
                'fr',
            )
            ->assertJsonPath(
                'data.is_new_user',
                false,
            )
            ->assertJsonPath(
                'data.next_step',
                'onboarding',
            )
            ->assertJsonPath(
                'data.authentication.token_type',
                'Bearer',
            )
            ->assertJsonStructure([
                'data' => [
                    'authentication' => [
                        'access_token',
                        'expires_at',
                    ],
                ],
            ]);

        $user->refresh();

        $this->assertNotNull(
            $user->email_verified_at,
        );

        $this->assertNotNull(
            $user->last_login_at,
        );

        $this->assertDatabaseHas(
            'personal_access_tokens',
            [
                'tokenable_id' => $user->id,
                'name' => 'Test iPhone',
            ],
        );

        $this->assertTrue(
            $issued->verification
                ->refresh()
                ->isConsumed(),
        );
    }

    public function test_unknown_email_does_not_create_account_during_login(): void
    {
        $issued = $this->issueLoginOtp(
            'unknown@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/login/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'unknown@example.com',
            ),
        );

        $response
            ->assertNotFound()
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'ACCOUNT_NOT_FOUND',
            )
            ->assertJsonPath(
                'error.details.suggested_action',
                'create_account',
            );

        $this->assertDatabaseCount(
            'users',
            0,
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0,
        );

        $this->assertTrue(
            $issued->verification
                ->refresh()
                ->isConsumed(),
        );
    }

    public function test_invalid_login_otp_is_rejected(): void
    {
        User::factory()->create([
            'email' => 'invalid@example.com',
        ]);

        $issued = $this->issueLoginOtp(
            'invalid@example.com',
        );

        $payload = $this->verificationPayload(
            issued: $issued,
            email: 'invalid@example.com',
        );

        $payload['code'] = '999999';

        $response = $this->postJson(
            '/api/v1/auth/login/verify-otp',
            $payload,
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'INVALID_OR_EXPIRED_OTP',
            );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0,
        );

        $this->assertSame(
            1,
            $issued->verification
                ->refresh()
                ->attempts,
        );
    }

    public function test_suspended_user_cannot_login(): void
    {
        $user = User::factory()->create([
            'email' => 'suspended@example.com',
            'status' => User::STATUS_SUSPENDED,
        ]);

        $issued = $this->issueLoginOtp(
            'suspended@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/login/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'suspended@example.com',
            ),
        );

        $response
            ->assertForbidden()
            ->assertJsonPath(
                'error.code',
                'ACCOUNT_UNAVAILABLE',
            );

        $this->assertDatabaseMissing(
            'personal_access_tokens',
            [
                'tokenable_id' => $user->id,
            ],
        );
    }

    public function test_completed_user_is_sent_to_home_after_login(): void
    {
        $user = User::factory()->create([
            'email' => 'complete@example.com',
            'status' => User::STATUS_ACTIVE,
            'onboarding_completed_at' => now(),
        ]);

        $issued = $this->issueLoginOtp(
            'complete@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/login/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'complete@example.com',
            ),
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.user.id',
                $user->public_id,
            )
            ->assertJsonPath(
                'data.user.onboarding_completed',
                true,
            )
            ->assertJsonPath(
                'data.next_step',
                'home',
            );
    }

    private function issueLoginOtp(
        string $email,
    ): IssuedEmailOtp {
        return app(EmailOtpService::class)->issue(
            email: $email,
            purpose: EmailVerificationPurpose::Login,
        );
    }

    /**
     * @return array<string, string>
     */
    private function verificationPayload(
        IssuedEmailOtp $issued,
        string $email,
        string $locale = 'en',
    ): array {
        return [
            'verification_id' => $issued
                ->verification
                ->public_id,
            'email' => $email,
            'code' => $issued->plainCode,
            'device_name' => 'Test iPhone',
            'locale' => $locale,
        ];
    }
}
