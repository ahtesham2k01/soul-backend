<?php

namespace App\Data\Auth;

final readonly class VerifiedGoogleIdentity
{
    public function __construct(
        public string $subject,
        public ?string $email,
        public bool $emailVerified,
        public ?string $name,
        public ?string $avatarUrl,
    ) {
    }
}
