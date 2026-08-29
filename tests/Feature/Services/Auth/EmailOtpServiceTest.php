<?php

namespace Tests\Feature\Services\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Models\EmailVerificationCode;
use App\Services\Auth\EmailOtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class EmailOtpServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_issues_a_secure_six_digit_otp(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'User@Example.com ',
            purpose: EmailVerificationPurpose::Register,
        );

        $verification = $issued->verification->refresh();

        $this->assertMatchesRegularExpression(
            '/^\d{6}$/',
            $issued->plainCode,
        );

        $this->assertTrue(
            Str::isUlid($verification->public_id),
        );

        $this->assertNotSame(
            'user@example.com',
            $verification->email_hash,
        );

        $this->assertNotSame(
            $issued->plainCode,
            $verification->code_hash,
        );

        $this->assertSame(
            EmailVerificationPurpose::Register,
            $verification->purpose,
        );

        $this->assertSame(
            0,
            $verification->attempts,
        );

        $this->assertFalse(
            $verification->isExpired(),
        );

        $this->assertFalse(
            $verification->isConsumed(),
        );

        $this->assertTrue(
            $verification->isUsable(),
        );
    }

    public function test_email_normalization_is_consistent(): void
    {
        $service = app(EmailOtpService::class);

        $this->assertSame(
            'user@example.com',
            $service->normalizeEmail(
                ' User@Example.COM ',
            ),
        );

        $this->assertSame(
            $service->hashEmail('user@example.com'),
            $service->hashEmail(
                $service->normalizeEmail(
                    ' User@Example.COM ',
                ),
            ),
        );
    }

    public function test_correct_otp_is_verified_and_consumed(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
        );

        $verified = $service->verify(
            verificationId: $issued->verification->public_id,
            email: 'USER@example.com',
            purpose: EmailVerificationPurpose::Register,
            plainCode: $issued->plainCode,
        );

        $this->assertNotNull(
            $verified,
        );

        $this->assertTrue(
            $verified->isConsumed(),
        );

        $this->assertFalse(
            $verified->isUsable(),
        );
    }

    public function test_wrong_otp_increments_attempts(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
        );

        $verified = $service->verify(
            verificationId: $issued->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
            plainCode: '999999',
        );

        $this->assertNull(
            $verified,
        );

        $verification = $issued->verification->refresh();

        $this->assertSame(
            1,
            $verification->attempts,
        );

        $this->assertFalse(
            $verification->isConsumed(),
        );
    }

    public function test_otp_is_rejected_after_maximum_attempts(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
        );

        for (
            $attempt = 1;
            $attempt <= EmailVerificationCode::MAX_ATTEMPTS;
            $attempt++
        ) {
            $service->verify(
                verificationId: $issued->verification->public_id,
                email: 'user@example.com',
                purpose: EmailVerificationPurpose::Login,
                plainCode: '999999',
            );
        }

        $verification = $issued->verification->refresh();

        $this->assertSame(
            EmailVerificationCode::MAX_ATTEMPTS,
            $verification->attempts,
        );

        $this->assertTrue(
            $verification->hasTooManyAttempts(),
        );

        $this->assertFalse(
            $verification->isUsable(),
        );

        $verified = $service->verify(
            verificationId: $verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
            plainCode: $issued->plainCode,
        );

        $this->assertNull(
            $verified,
        );
    }

    public function test_expired_otp_is_rejected(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
        );

        $this->travel(
            EmailOtpService::EXPIRES_AFTER_MINUTES + 1,
        )->minutes();

        $verified = $service->verify(
            verificationId: $issued->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
            plainCode: $issued->plainCode,
        );

        $this->assertNull(
            $verified,
        );

        $this->assertTrue(
            $issued->verification->refresh()->isExpired(),
        );
    }

    public function test_consumed_otp_cannot_be_used_twice(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
        );

        $firstVerification = $service->verify(
            verificationId: $issued->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
            plainCode: $issued->plainCode,
        );

        $secondVerification = $service->verify(
            verificationId: $issued->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
            plainCode: $issued->plainCode,
        );

        $this->assertNotNull(
            $firstVerification,
        );

        $this->assertNull(
            $secondVerification,
        );
    }

    public function test_issuing_new_otp_invalidates_previous_otp(): void
    {
        $service = app(EmailOtpService::class);

        $first = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
        );

        $second = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
        );

        $this->assertTrue(
            $first->verification->refresh()->isConsumed(),
        );

        $this->assertFalse(
            $second->verification->refresh()->isConsumed(),
        );

        $oldResult = $service->verify(
            verificationId: $first->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
            plainCode: $first->plainCode,
        );

        $newResult = $service->verify(
            verificationId: $second->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
            plainCode: $second->plainCode,
        );

        $this->assertNull(
            $oldResult,
        );

        $this->assertNotNull(
            $newResult,
        );
    }

    public function test_otp_cannot_be_used_for_another_purpose(): void
    {
        $service = app(EmailOtpService::class);

        $issued = $service->issue(
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Register,
        );

        $verified = $service->verify(
            verificationId: $issued->verification->public_id,
            email: 'user@example.com',
            purpose: EmailVerificationPurpose::Login,
            plainCode: $issued->plainCode,
        );

        $this->assertNull(
            $verified,
        );

        $this->assertFalse(
            $issued->verification->refresh()->isConsumed(),
        );
    }
}
