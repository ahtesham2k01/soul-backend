<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RecordUserActivity
{
    public function handle(Request $request, Closure $next): Response
    {
        $profile = $request->user()?->profile;

        if ($profile !== null && ($profile->last_active_at === null || $profile->last_active_at->lt(now()->subMinutes(15)))) {
            $profile->forceFill(['last_active_at' => now()])->saveQuietly();
        }

        return $next($request);
    }
}
