<?php

namespace App\Http\Controllers\Api\V1\Matching;

use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class StoreProfileDecisionController extends Controller
{
    public function __invoke(Request $request, string $profile): JsonResponse
    {
        $validated = $request->validate(['decision' => ['required', Rule::in(['like', 'pass'])]]);
        $actor = $request->user();
        $target = UserProfile::query()->where('public_id', $profile)->where('profile_status', ProfileStatus::Live->value)
            ->whereHas('user', fn ($query) => $query->where('status', User::STATUS_ACTIVE))->first();

        if ($target === null) return ApiResponse::error('PROFILE_UNAVAILABLE', 'This profile is not available.', 404);
        if ($target->user_id === $actor->id) return ApiResponse::error('SELF_DECISION_NOT_ALLOWED', 'You cannot decide on your own profile.', 422);

        $match = DB::transaction(function () use ($actor, $target, $validated): ?UserMatch {
            $ids = [$actor->id, $target->user_id]; sort($ids);
            $existing = UserMatch::query()->where('first_user_id', $ids[0])->where('second_user_id', $ids[1])->first();
            if ($existing?->status === 'active') return $existing;

            ProfileDecision::query()->updateOrCreate(
                ['actor_user_id' => $actor->id, 'target_user_id' => $target->user_id],
                ['decision' => $validated['decision']],
            );
            if ($validated['decision'] !== 'like') return null;

            $reciprocal = ProfileDecision::query()->where('actor_user_id', $target->user_id)
                ->where('target_user_id', $actor->id)->where('decision', 'like')->exists();
            return $reciprocal ? UserMatch::query()->updateOrCreate(
                ['first_user_id' => $ids[0], 'second_user_id' => $ids[1]],
                ['status' => 'active', 'matched_at' => now(), 'ended_at' => null, 'ended_by_user_id' => null],
            ) : null;
        });

        return ApiResponse::success([
            'decision' => $validated['decision'],
            'matched' => $match?->status === 'active',
            'match_id' => $match?->public_id,
        ], 'Profile decision saved successfully.');
    }
}
