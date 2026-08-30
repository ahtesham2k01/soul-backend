<?php

namespace App\Contracts\Auth;

use App\Data\Auth\VerifiedGoogleIdentity;

interface GoogleTokenVerifier
{
    public function verify(
        string $idToken,
    ): ?VerifiedGoogleIdentity;
}
