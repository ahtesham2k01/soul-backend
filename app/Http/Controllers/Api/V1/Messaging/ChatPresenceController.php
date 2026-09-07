<?php

namespace App\Http\Controllers\Api\V1\Messaging;

use App\Http\Controllers\Controller;
use App\Models\UserMatch;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ChatPresenceController extends Controller
{
    private const TYPING_TTL_SECONDS = 8;

    public function show(Request $request, string $match): JsonResponse
    {
        $record = $this->activeMatch($request, $match);
        if ($record === null) {
            return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        }

        $other = $record->first_user_id === $request->user()->id ? $record->secondUser : $record->firstUser;
        $lastSeen = $other->profile?->last_active_at;

        return ApiResponse::success([
            'is_online' => $lastSeen?->gte(now()->subMinutes(2)) ?? false,
            'last_seen_at' => $lastSeen?->toIso8601String(),
            'is_typing' => Cache::has($this->typingKey($record, $other->id)),
            'typing_expires_in_seconds' => self::TYPING_TTL_SECONDS,
        ]);
    }

    public function typing(Request $request, string $match): JsonResponse
    {
        $validated = $request->validate(['is_typing' => ['required', 'boolean']]);
        $record = $this->activeMatch($request, $match);
        if ($record === null) {
            return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        }

        $key = $this->typingKey($record, $request->user()->id);
        if ($validated['is_typing']) {
            Cache::put($key, true, now()->addSeconds(self::TYPING_TTL_SECONDS));
        } else {
            Cache::forget($key);
        }

        return ApiResponse::success([
            'is_typing' => $validated['is_typing'],
            'typing_expires_in_seconds' => self::TYPING_TTL_SECONDS,
        ]);
    }

    private function typingKey(UserMatch $match, int $userId): string
    {
        return "chat:{$match->public_id}:typing:{$userId}";
    }

    private function activeMatch(Request $request, string $publicId): ?UserMatch
    {
        $userId = $request->user()->id;

        return UserMatch::query()->where('public_id', $publicId)->where('status', 'active')
            ->where(fn ($query) => $query->where('first_user_id', $userId)->orWhere('second_user_id', $userId))
            ->whereHas('firstUser', fn ($query) => $query->where('status', 'active'))
            ->whereHas('secondUser', fn ($query) => $query->where('status', 'active'))
            ->with(['firstUser.profile', 'secondUser.profile'])
            ->first();
    }
}
