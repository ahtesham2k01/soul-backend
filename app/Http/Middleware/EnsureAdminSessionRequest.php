<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminSessionRequest
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response|JsonResponse
    {
        $authorization = $request->header('Authorization');

        if (is_string($authorization) && preg_match('/^\s*Bearer(?:\s|$)/i', $authorization) === 1) {
            return ApiResponse::error(
                code: 'ADMIN_SESSION_REQUIRED',
                message: 'Admin access requires a secure browser session.',
                status: 401,
            );
        }

        return $next($request);
    }
}
