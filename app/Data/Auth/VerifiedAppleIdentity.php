<?php

namespace App\Data\Auth;

final readonly class VerifiedAppleIdentity
{
    public function __construct(
        public string $subject,
        public ?string $email,
        public bool $emailVerified,
        public bool $isPrivateEmail,
    ) {
    }
}
