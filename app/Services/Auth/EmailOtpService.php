<?php

namespace App\Services\Auth;

use App\Data\Auth\IssuedEmailOtp;
use App\Enums\Auth\EmailVerificationPurpose;
use App\Models\EmailVerificationCode;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

final class EmailOtpService
{
    public const CODE_LENGTH = 6;

    public const EXPIRES_AFTER_MINUTES = 3;

    /**
     * Generate and securely store a new email OTP.
     */
    public function issue(
        string $email,
        EmailVerificationPurpose $purpose,
    ): IssuedEmailOtp {
        $normalizedEmail = $this->normalizeEmail(
            $email,
        );

        $emailHash = $this->hashEmail(
            $normalizedEmail,
        );

        return DB::transaction(
            function () use (
                $emailHash,
                $purpose,
            ): IssuedEmailOtp {
                EmailVerificationCode::query()
                    ->where('email_hash', $emailHash)
                    ->where('purpose', $purpose->value)
                    ->whereNull('consumed_at')
                    ->update([
                        'consumed_at' => now(),
                        'updated_at' => now(),
                    ]);

                $plainCode = $this->generateCode();
                $publicId = (string) Str::ulid();

                $verification = new EmailVerificationCode([
                    'email_hash' => $emailHash,
                    'purpose' => $purpose,
                    'code_hash' => $this->hashCode(
                        publicId: $publicId,
                        emailHash: $emailHash,
                        purpose: $purpose,
                        plainCode: $plainCode,
                    ),
                    'expires_at' => now()->addMinutes(
                        self::EXPIRES_AFTER_MINUTES,
                    ),
                ]);

                $verification->public_id = $publicId;
                $verification->save();

                return new IssuedEmailOtp(
                    verification: $verification,
                    plainCode: $plainCode,
                );
            },
        );
    }

    /**
     * Verify and consume an email OTP.
     */
    public function verify(
        string $verificationId,
        string $email,
        EmailVerificationPurpose $purpose,
        string $plainCode,
    ): ?EmailVerificationCode {
        $normalizedEmail = $this->normalizeEmail(
            $email,
        );

        $emailHash = $this->hashEmail(
            $normalizedEmail,
        );

        return DB::transaction(
            function () use (
                $verificationId,
                $emailHash,
                $purpose,
                $plainCode,
            ): ?EmailVerificationCode {
                $verification = EmailVerificationCode::query()
                    ->where('public_id', $verificationId)
                    ->where('email_hash', $emailHash)
                    ->where('purpose', $purpose->value)
                    ->lockForUpdate()
                    ->first();

                if ($verification === null) {
                    return null;
                }

                if (! $verification->isUsable()) {
                    return null;
                }

                $expectedHash = $this->hashCode(
                    publicId: $verification->public_id,
                    emailHash: $emailHash,
                    purpose: $purpose,
                    plainCode: $plainCode,
                );

                if (! hash_equals(
                    $verification->code_hash,
                    $expectedHash,
                )) {
                    $verification->recordFailedAttempt();

                    return null;
                }

                $verification->markAsConsumed();

                return $verification;
            },
        );
    }

    /**
     * Normalize email addresses before lookup.
     */
    public function normalizeEmail(string $email): string
    {
        return Str::lower(
            trim($email),
        );
    }

    /**
     * Create a non-reversible email lookup hash.
     */
    public function hashEmail(string $normalizedEmail): string
    {
        return hash_hmac(
            'sha256',
            $normalizedEmail,
            $this->secret(),
        );
    }

    /**
     * Generate a cryptographically secure six-digit code.
     */
    private function generateCode(): string
    {
        return str_pad(
            (string) random_int(
                0,
                (10 ** self::CODE_LENGTH) - 1,
            ),
            self::CODE_LENGTH,
            '0',
            STR_PAD_LEFT,
        );
    }

    /**
     * Bind the OTP hash to its request, email and purpose.
     */
    private function hashCode(
        string $publicId,
        string $emailHash,
        EmailVerificationPurpose $purpose,
        string $plainCode,
    ): string {
        return hash_hmac(
            'sha256',
            implode('|', [
                $publicId,
                $emailHash,
                $purpose->value,
                $plainCode,
            ]),
            $this->secret(),
        );
    }

    /**
     * Return the application secret used for OTP HMAC operations.
     */
    private function secret(): string
    {
        $secret = config('app.key');

        if (! is_string($secret) || $secret === '') {
            throw new RuntimeException(
                'APP_KEY is required for email OTP security.',
            );
        }

        return $secret;
    }
}
