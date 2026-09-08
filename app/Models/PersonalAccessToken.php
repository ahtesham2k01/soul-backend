<?php

namespace App\Models;

use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken as SanctumPersonalAccessToken;

class PersonalAccessToken extends SanctumPersonalAccessToken
{
    protected static function booted(): void
    {
        static::creating(function (PersonalAccessToken $token): void {
            $token->public_id ??= (string) Str::ulid();
        });
    }
}
