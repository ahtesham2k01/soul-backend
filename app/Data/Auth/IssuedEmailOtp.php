<?php

namespace App\Data\Auth;

use App\Models\EmailVerificationCode;

final readonly class IssuedEmailOtp
{
    public function __construct(
        public EmailVerificationCode $verification,
        public string $plainCode,
    ) {
    }
}
