<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountIsActive
{
    /**
     * Handle an incoming request.
     *
     * @param Closure(Request): Response $next
     */
    public function handle(
        Request $request,
        Closure $next,
    ): Response|JsonResponse {
        $user = $request->user();

        if ($user === null) {
            return ApiResponse::error(
                code: 'UNAUTHENTICATED',
                message: 'Authentication is required.',
                status: 401,
            );
        }

        if ($user->status !== User::STATUS_ACTIVE) {
            return ApiResponse::error(
                code: 'ACCOUNT_UNAVAILABLE',
                message: 'This account is currently unavailable.',
                status: 403,
            );
        }

        return $next($request);
    }
}
