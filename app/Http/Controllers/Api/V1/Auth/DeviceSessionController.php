<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceSessionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $currentTokenId = $request->user()->currentAccessToken()?->getKey();

        $maximum = max(1, (int) config('soul.security.maximum_active_sessions', 20));
        $sessions = $request->user()->tokens()
            ->where(function ($query): void {
                $query->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->latest('last_used_at')
            ->latest('id')
            ->limit($maximum + 1)
            ->get();
        $hasMore = $sessions->count() > $maximum;
        $sessions = $sessions->take($maximum)->map(fn ($token): array => [
                'id' => $token->public_id,
                'device_name' => $token->name,
                'is_current' => $token->getKey() === $currentTokenId,
                'last_used_at' => $token->last_used_at?->toISOString(),
                'created_at' => $token->created_at?->toISOString(),
                'expires_at' => $token->expires_at?->toISOString(),
            ])
            ->values();

        return ApiResponse::success(
            data: ['sessions' => $sessions, 'has_more' => $hasMore],
            message: 'Active device sessions loaded successfully.',
        );
    }

    public function destroy(Request $request, string $session): JsonResponse
    {
        $token = $request->user()->tokens()->where('public_id', $session)->first();

        if ($token === null) {
            return ApiResponse::error(
                code: 'DEVICE_SESSION_NOT_FOUND',
                message: 'Device session not found.',
                status: 404,
            );
        }

        $wasCurrent = $token->getKey() === $request->user()->currentAccessToken()?->getKey();
        $token->delete();

        return ApiResponse::success(
            data: ['revoked' => true, 'was_current' => $wasCurrent],
            message: 'Device session signed out successfully.',
        );
    }
}
