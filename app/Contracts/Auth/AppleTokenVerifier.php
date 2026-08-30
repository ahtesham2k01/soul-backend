<?php

namespace App\Contracts\Auth;

use App\Data\Auth\VerifiedAppleIdentity;

interface AppleTokenVerifier
{
    public function verify(
        string $identityToken,
        string $rawNonce,
    ): ?VerifiedAppleIdentity;
}
