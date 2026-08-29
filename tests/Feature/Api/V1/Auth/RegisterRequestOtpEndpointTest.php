<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Mail\Auth\EmailOtpMail;
use App\Models\EmailVerificationCode;
use App\Services\Auth\EmailOtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Tests\TestCase;

class RegisterRequestOtpEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_otp_can_be_requested(): void
    {
        Mail::fake();

        $response = $this->postJson(
            '/api/v1/auth/register/request-otp',
            [
                'email' => ' User@Example.COM ',
                'locale' => 'en',
            ],
        );

        $requestId = $response->headers->get(
            'X-Request-ID',
        );

        $response
            ->assertAccepted()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'message',
                'If the email is valid, a verification code has been sent.',
            )
            ->assertJsonPath(
                'data.expires_in_seconds',
                180,
            )
            ->assertJsonPath(
                'data.resend_after_seconds',
                60,
            )
            ->assertJsonPath(
                'meta.request_id',
                $requestId,
            );

        $verificationId = $response->json(
            'data.verification_id',
        );

        $this->assertIsString(
            $verificationId,
        );

        $this->assertTrue(
            Str::isUlid($verificationId),
        );

        $verification = EmailVerificationCode::query()
            ->where('public_id', $verificationId)
            ->first();

        $this->assertNotNull(
            $verification,
        );

        $this->assertSame(
            EmailVerificationPurpose::Register,
            $verification->purpose,
        );

        $this->assertSame(
            app(EmailOtpService::class)->hashEmail(
                'user@example.com',
            ),
            $verification->email_hash,
        );

        $this->assertFalse(
            $verification->isConsumed(),
        );

        $this->assertTrue(
            $verification->isUsable(),
        );

        Mail::assertSent(
            EmailOtpMail::class,
            function (EmailOtpMail $mail): bool {
                return $mail->hasTo(
                    'user@example.com',
                )
                    && $mail->purpose
                        === EmailVerificationPurpose::Register
                    && preg_match(
                        '/^\d{6}$/',
                        $mail->code,
                    ) === 1;
            },
        );
    }

    public function test_invalid_email_returns_standard_validation_error(): void
    {
        Mail::fake();

        $response = $this->postJson(
            '/api/v1/auth/register/request-otp',
            [
                'email' => 'not-an-email',
                'locale' => 'en',
            ],
        );

        $response
            ->assertUnprocessable()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'VALIDATION_ERROR',
            )
            ->assertJsonStructure([
                'error' => [
                    'details' => [
                        'fields' => [
                            'email',
                        ],
                    ],
                ],
                'meta' => [
                    'request_id',
                ],
            ]);

        Mail::assertNothingSent();

        $this->assertDatabaseCount(
            'email_verification_codes',
            0,
        );
    }

    public function test_unsupported_locale_is_rejected(): void
    {
        Mail::fake();

        $response = $this->postJson(
            '/api/v1/auth/register/request-otp',
            [
                'email' => 'user@example.com',
                'locale' => 'xx-ZZ',
            ],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'VALIDATION_ERROR',
            )
            ->assertJsonStructure([
                'error' => [
                    'details' => [
                        'fields' => [
                            'locale',
                        ],
                    ],
                ],
            ]);

        Mail::assertNothingSent();
    }

    public function test_email_otp_request_is_rate_limited(): void
    {
        Mail::fake();

        $payload = [
            'email' => 'rate-limit@example.com',
            'locale' => 'en',
        ];

        $this->postJson(
            '/api/v1/auth/register/request-otp',
            $payload,
        )->assertAccepted();

        $response = $this->postJson(
            '/api/v1/auth/register/request-otp',
            $payload,
        );

        $response
            ->assertTooManyRequests()
            ->assertHeader('Retry-After')
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'RATE_LIMIT_EXCEEDED',
            )
            ->assertJsonStructure([
                'error' => [
                    'details' => [
                        'retry_after_seconds',
                    ],
                ],
                'meta' => [
                    'request_id',
                ],
            ]);

        Mail::assertSentCount(1);

        $this->assertDatabaseCount(
            'email_verification_codes',
            1,
        );
    }
}
