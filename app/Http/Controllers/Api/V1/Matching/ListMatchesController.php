<?php

namespace App\Http\Controllers\Api\V1\Matching;

use App\Http\Controllers\Controller;
use App\Models\UserMatch;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ListMatchesController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $page = UserMatch::query()->where('status', 'active')
            ->where(fn ($query) => $query->where('first_user_id', $user->id)->orWhere('second_user_id', $user->id))
            ->whereHas('firstUser', fn ($query) => $query->where('status', 'active'))
            ->whereHas('secondUser', fn ($query) => $query->where('status', 'active'))
            ->with([
                'firstUser.profile',
                'secondUser.profile',
                'conversation' => fn ($query) => $query
                    ->with('latestMessage')
                    ->withCount(['messages as unread_messages_count' => fn ($messages) => $messages
                        ->where('sender_user_id', '!=', $user->id)
                        ->whereNull('read_at')]),
            ])
            ->orderByDesc('matched_at')->cursorPaginate(20);

        return ApiResponse::success([
            'matches' => collect($page->items())->map(function (UserMatch $match) use ($user): array {
                $other = $match->first_user_id === $user->id ? $match->secondUser : $match->firstUser;
                $lastSeen = $other->profile->last_active_at;
                $latest = $match->conversation?->latestMessage;

                return [
                    'id' => $match->public_id,
                    'matched_at' => $match->matched_at->toIso8601String(),
                    'profile' => [
                        'id' => $other->profile->public_id,
                        'first_name' => $other->profile->first_name,
                    ],
                    'presence' => [
                        'is_online' => $lastSeen?->gte(now()->subMinutes(2)) ?? false,
                        'last_seen_at' => $lastSeen?->toIso8601String(),
                    ],
                    'conversation' => [
                        'last_message' => $latest === null ? null : [
                            'id' => $latest->public_id,
                            'body' => $latest->body,
                            'is_mine' => $latest->sender_user_id === $user->id,
                            'sent_at' => $latest->created_at->toIso8601String(),
                        ],
                        'unread_count' => (int) ($match->conversation?->unread_messages_count ?? 0),
                    ],
                ];
            })->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
