<?php

namespace App\Services\Auth;

use App\Models\User;
use Laravel\Sanctum\NewAccessToken;

class MobileTokenIssuer
{
    public function issue(User $user, string $deviceName): NewAccessToken
    {
        $now = now();
        $user->tokens()->whereNotNull('expires_at')->where('expires_at', '<=', $now)->delete();
        $token = $user->createToken($deviceName, ['mobile'], $now->copy()->addDays(90));
        $maximum = max(1, (int) config('soul.security.maximum_active_sessions', 20));
        $excessIds = $user->tokens()
            ->where(fn ($query) => $query->whereNull('expires_at')->orWhere('expires_at', '>', $now))
            ->whereKeyNot($token->accessToken->getKey())
            ->latest('last_used_at')->latest('id')
            ->skip($maximum - 1)->take(1000)->pluck('id');

        if ($excessIds->isNotEmpty()) {
            $user->tokens()->whereIn('id', $excessIds)->delete();
        }

        return $token;
    }
}
