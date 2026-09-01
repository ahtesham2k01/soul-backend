<?php

namespace App\Http\Controllers\Api\V1\Matching;

use App\Http\Controllers\Controller;
use App\Models\UserMatch;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UnmatchController extends Controller
{
    public function __invoke(Request $request, string $match): JsonResponse
    {
        $user = $request->user();
        $record = UserMatch::query()->where('public_id', $match)
            ->where(fn ($query) => $query->where('first_user_id', $user->id)->orWhere('second_user_id', $user->id))
            ->first();

        if ($record === null) return ApiResponse::error('MATCH_NOT_FOUND', 'Match not found.', 404);
        if ($record->status === 'active') {
            $record->update(['status' => 'unmatched', 'ended_at' => now(), 'ended_by_user_id' => $user->id]);
        }

        return ApiResponse::success(['match_id' => $record->public_id, 'status' => 'unmatched'], 'Match ended successfully.');
    }
}
