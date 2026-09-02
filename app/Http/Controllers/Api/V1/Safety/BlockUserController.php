<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Http\Controllers\Controller;
use App\Models\ProfileDecision;
use App\Models\UserBlock;
use App\Models\UserMatch;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BlockUserController extends Controller
{
    public function __invoke(Request $request, string $profile): JsonResponse
    {
        $validated = $request->validate(['reason' => ['nullable', 'string', 'max:500']]);
        $target = UserProfile::query()->where('public_id', $profile)->first();
        if ($target === null || $target->user_id === $request->user()->id) return ApiResponse::error('PROFILE_UNAVAILABLE', 'Profile unavailable.', 404);
        DB::transaction(function () use ($request, $target, $validated): void {
            $actor = $request->user()->id;
            UserBlock::query()->firstOrCreate(['blocker_user_id' => $actor, 'blocked_user_id' => $target->user_id], ['reason' => $validated['reason'] ?? null]);
            UserMatch::query()->where('status', 'active')->where(fn ($q) => $q
                ->where(fn ($q) => $q->where('first_user_id', $actor)->where('second_user_id', $target->user_id))
                ->orWhere(fn ($q) => $q->where('first_user_id', $target->user_id)->where('second_user_id', $actor)))
                ->update(['status' => 'blocked', 'ended_at' => now(), 'ended_by_user_id' => $actor]);
            ProfileDecision::query()->where(fn ($q) => $q
                ->where(['actor_user_id' => $actor, 'target_user_id' => $target->user_id])
                ->orWhere(fn ($q) => $q->where(['actor_user_id' => $target->user_id, 'target_user_id' => $actor])))->delete();
        });
        return ApiResponse::success(['blocked' => true], 'User blocked successfully.');
    }
}
