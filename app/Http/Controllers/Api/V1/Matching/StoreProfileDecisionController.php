<?php

namespace App\Http\Controllers\Api\V1\Matching;

use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\NotificationPreference;
use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserBlock;
use App\Models\UserMatch;
use App\Models\UserNotification;
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

        if ($actor->profile?->profile_status !== ProfileStatus::Live) {
            return ApiResponse::error(
                'DISCOVERY_NOT_READY',
                'Your profile must be live before making profile decisions.',
                409,
            );
        }

        $target = UserProfile::query()->where('public_id', $profile)->where('profile_status', ProfileStatus::Live->value)
            ->whereHas('user', fn ($query) => $query->where('status', User::STATUS_ACTIVE))
            ->whereDoesntHave('user.privacySetting', fn ($query) => $query->where('discoverable', false))
            ->whereDoesntHave('user.privacySetting', fn ($query) => $query->where('profile_paused', true))
            ->where('last_active_at', '>=', now()->subDays(90))
            ->where(function ($visible) use ($actor): void {
                $visible->whereDoesntHave('user.privacySetting', fn ($privacy) => $privacy->where('incognito', true))
                    ->orWhereExists(fn ($decision) => $decision->selectRaw('1')->from('profile_decisions')
                        ->whereColumn('actor_user_id', 'user_profiles.user_id')
                        ->where('target_user_id', $actor->id)
                        ->where('decision', 'like'));
            })
            ->first();

        if ($target !== null && $actor->privacySetting?->hide_contacts && $target->user->phone_lookup_hash !== null
            && $actor->hiddenContactHashes()->where('phone_hash', $target->user->phone_lookup_hash)->exists()) {
            $target = null;
        }

        if ($target === null) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'This profile is not available.', 404);
        }
        if ($target->user_id === $actor->id) {
            return ApiResponse::error('SELF_DECISION_NOT_ALLOWED', 'You cannot decide on your own profile.', 422);
        }
        $blocked = UserBlock::query()->where(fn ($query) => $query
            ->where(['blocker_user_id' => $actor->id, 'blocked_user_id' => $target->user_id])
            ->orWhere(fn ($query) => $query->where([
                'blocker_user_id' => $target->user_id, 'blocked_user_id' => $actor->id,
            ])))->exists();
        if ($blocked) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'This profile is not available.', 404);
        }

        $match = DB::transaction(function () use ($actor, $target, $validated): ?UserMatch {
            $ids = [$actor->id, $target->user_id];
            sort($ids);
            $existing = UserMatch::query()->where('first_user_id', $ids[0])->where('second_user_id', $ids[1])->first();
            if ($existing?->status === 'active') {
                return $existing;
            }

            ProfileDecision::query()->updateOrCreate(
                ['actor_user_id' => $actor->id, 'target_user_id' => $target->user_id],
                ['decision' => $validated['decision']],
            );
            if ($validated['decision'] !== 'like') {
                return null;
            }

            $reciprocal = ProfileDecision::query()->where('actor_user_id', $target->user_id)
                ->where('target_user_id', $actor->id)->where('decision', 'like')->exists();

            return $reciprocal ? UserMatch::query()->updateOrCreate(
                ['first_user_id' => $ids[0], 'second_user_id' => $ids[1]],
                ['status' => 'active', 'matched_at' => now(), 'ended_at' => null, 'ended_by_user_id' => null],
            ) : null;
        });

        if ($match?->wasRecentlyCreated) {
            foreach ([$actor->id, $target->user_id] as $userId) {
                $enabled = NotificationPreference::query()
                    ->where('user_id', $userId)->value('new_matches');
                if ($enabled !== false && $enabled !== 0) {
                    UserNotification::query()->create([
                        'user_id' => $userId, 'type' => 'new_match',
                        'data' => ['match_id' => $match->public_id],
                    ]);
                }
            }
        }

        return ApiResponse::success([
            'decision' => $validated['decision'],
            'matched' => $match?->status === 'active',
            'match_id' => $match?->public_id,
        ], 'Profile decision saved successfully.');
    }
}
