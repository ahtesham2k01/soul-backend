<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Models\EmailVerificationCode;
use App\Models\User;
use App\Services\Auth\EmailOtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class RegisterVerifyOtpEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_new_user_is_created_and_receives_token(): void
    {
        $issued = $this->issueRegistrationOtp(
            'new@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'new@example.com',
            ),
        );

        $requestId = $response->headers->get(
            'X-Request-ID',
        );

        $response
            ->assertCreated()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'message',
                'Account created successfully.',
            )
            ->assertJsonPath(
                'data.is_new_user',
                true,
            )
            ->assertJsonPath(
                'data.next_step',
                'onboarding',
            )
            ->assertJsonPath(
                'data.user.email',
                'new@example.com',
            )
            ->assertJsonPath(
                'data.user.email_verified',
                true,
            )
            ->assertJsonPath(
                'data.user.preferred_locale',
                'en',
            )
            ->assertJsonPath(
                'data.user.status',
                User::STATUS_ACTIVE,
            )
            ->assertJsonPath(
                'data.user.onboarding_completed',
                false,
            )
            ->assertJsonPath(
                'data.authentication.token_type',
                'Bearer',
            )
            ->assertJsonPath(
                'meta.request_id',
                $requestId,
            );

        $publicUserId = $response->json(
            'data.user.id',
        );

        $accessToken = $response->json(
            'data.authentication.access_token',
        );

        $expiresAt = $response->json(
            'data.authentication.expires_at',
        );

        $this->assertIsString(
            $publicUserId,
        );

        $this->assertTrue(
            Str::isUlid($publicUserId),
        );

        $this->assertIsString(
            $accessToken,
        );

        $this->assertStringContainsString(
            '|',
            $accessToken,
        );

        $this->assertIsString(
            $expiresAt,
        );

        $user = User::query()
            ->where('public_id', $publicUserId)
            ->first();

        $this->assertNotNull(
            $user,
        );

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
                'name' => 'Test Android',
            ],
        );

        $this->assertTrue(
            $issued->verification
                ->refresh()
                ->isConsumed(),
        );
    }

    public function test_existing_user_is_signed_in_without_duplicate_account(): void
    {
        $existingUser = User::factory()->create([
            'email' => 'existing@example.com',
            'email_verified_at' => null,
            'preferred_locale' => 'en',
            'status' => User::STATUS_ACTIVE,
        ]);

        $issued = $this->issueRegistrationOtp(
            'existing@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'existing@example.com',
                locale: 'es',
            ),
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'message',
                'Signed in successfully.',
            )
            ->assertJsonPath(
                'data.is_new_user',
                false,
            )
            ->assertJsonPath(
                'data.user.id',
                $existingUser->public_id,
            )
            ->assertJsonPath(
                'data.user.preferred_locale',
                'es',
            );

        $this->assertDatabaseCount(
            'users',
            1,
        );

        $existingUser->refresh();

        $this->assertNotNull(
            $existingUser->email_verified_at,
        );

        $this->assertNotNull(
            $existingUser->last_login_at,
        );
    }

    public function test_invalid_otp_is_rejected_without_creating_user(): void
    {
        $issued = $this->issueRegistrationOtp(
            'invalid@example.com',
        );

        $payload = $this->verificationPayload(
            issued: $issued,
            email: 'invalid@example.com',
        );

        $payload['code'] = '999999';

        $response = $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $payload,
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'INVALID_OR_EXPIRED_OTP',
            );

        $this->assertDatabaseCount(
            'users',
            0,
        );

        $this->assertSame(
            1,
            $issued->verification
                ->refresh()
                ->attempts,
        );
    }

    public function test_expired_otp_is_rejected(): void
    {
        $issued = $this->issueRegistrationOtp(
            'expired@example.com',
        );

        $this->travel(
            EmailOtpService::EXPIRES_AFTER_MINUTES + 1,
        )->minutes();

        $response = $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'expired@example.com',
            ),
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'INVALID_OR_EXPIRED_OTP',
            );

        $this->assertDatabaseCount(
            'users',
            0,
        );
    }

    public function test_consumed_otp_cannot_create_another_token(): void
    {
        $issued = $this->issueRegistrationOtp(
            'single-use@example.com',
        );

        $payload = $this->verificationPayload(
            issued: $issued,
            email: 'single-use@example.com',
        );

        $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $payload,
        )->assertCreated();

        $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $payload,
        )
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'INVALID_OR_EXPIRED_OTP',
            );

        $this->assertDatabaseCount(
            'users',
            1,
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            1,
        );
    }

    public function test_suspended_account_does_not_receive_token(): void
    {
        $user = User::factory()->create([
            'email' => 'suspended@example.com',
            'status' => User::STATUS_SUSPENDED,
        ]);

        $issued = $this->issueRegistrationOtp(
            'suspended@example.com',
        );

        $response = $this->postJson(
            '/api/v1/auth/register/verify-otp',
            $this->verificationPayload(
                issued: $issued,
                email: 'suspended@example.com',
            ),
        );

        $response
            ->assertForbidden()
            ->assertJsonPath(
                'success',
                false,
            )
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

    private function issueRegistrationOtp(
        string $email,
    ): \App\Data\Auth\IssuedEmailOtp {
        return app(EmailOtpService::class)->issue(
            email: $email,
            purpose: EmailVerificationPurpose::Register,
        );
    }

    /**
     * @return array<string, string>
     */
    private function verificationPayload(
        \App\Data\Auth\IssuedEmailOtp $issued,
        string $email,
        string $locale = 'en',
    ): array {
        return [
            'verification_id' => $issued
                ->verification
                ->public_id,
            'email' => $email,
            'code' => $issued->plainCode,
            'device_name' => 'Test Android',
            'locale' => $locale,
        ];
    }
}
