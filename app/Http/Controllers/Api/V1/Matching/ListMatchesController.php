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
            ->with(['firstUser.profile', 'secondUser.profile'])
            ->orderByDesc('matched_at')->cursorPaginate(20);

        return ApiResponse::success([
            'matches' => collect($page->items())->map(function (UserMatch $match) use ($user): array {
                $other = $match->first_user_id === $user->id ? $match->secondUser : $match->firstUser;
                return [
                    'id' => $match->public_id,
                    'matched_at' => $match->matched_at->toIso8601String(),
                    'profile' => [
                        'id' => $other->profile->public_id,
                        'first_name' => $other->profile->first_name,
                    ],
                ];
            })->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
