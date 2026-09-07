<?php

namespace App\Http\Controllers\Api\V1\Matching;

use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use App\Support\Notifications\UserNotifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class LikeRequestController extends Controller
{
    public function __construct(private readonly UserNotifier $notifier) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $page = ProfileDecision::query()
            ->where('target_user_id', $user->id)
            ->where('decision', 'like')
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('profile_decisions as response')
                ->whereColumn('response.actor_user_id', 'profile_decisions.target_user_id')
                ->whereColumn('response.target_user_id', 'profile_decisions.actor_user_id'))
            ->whereHas('actor', fn ($query) => $query->where('status', User::STATUS_ACTIVE)
                ->whereHas('profile', fn ($profile) => $profile->where('profile_status', ProfileStatus::Live->value)))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('user_blocks')
                ->where(fn ($block) => $block
                    ->whereColumn('blocker_user_id', 'profile_decisions.actor_user_id')
                    ->where('blocked_user_id', $user->id))
                ->orWhere(fn ($block) => $block
                    ->where('blocker_user_id', $user->id)
                    ->whereColumn('blocked_user_id', 'profile_decisions.actor_user_id')))
            ->with(['actor.profile'])
            ->orderByDesc('id')
            ->cursorPaginate(20);

        return ApiResponse::success([
            'requests' => collect($page->items())->map(fn (ProfileDecision $like) => [
                'profile' => [
                    'id' => $like->actor->profile->public_id,
                    'first_name' => $like->actor->profile->first_name,
                ],
                'received_at' => $like->created_at->toIso8601String(),
            ])->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function respond(Request $request, string $profile): JsonResponse
    {
        $validated = $request->validate(['decision' => ['required', Rule::in(['accept', 'decline'])]]);
        $user = $request->user();
        $requester = $this->availableRequester($user, $profile);

        if ($requester === null) {
            return ApiResponse::error('LIKE_REQUEST_NOT_FOUND', 'Pending like request not found.', 404);
        }

        $match = DB::transaction(function () use ($user, $requester, $validated): ?UserMatch {
            ProfileDecision::query()->updateOrCreate(
                ['actor_user_id' => $user->id, 'target_user_id' => $requester->id],
                ['decision' => $validated['decision'] === 'accept' ? 'like' : 'pass'],
            );

            if ($validated['decision'] === 'decline') {
                return null;
            }

            $ids = [$user->id, $requester->id];
            sort($ids);

            return UserMatch::query()->updateOrCreate(
                ['first_user_id' => $ids[0], 'second_user_id' => $ids[1]],
                ['status' => 'active', 'matched_at' => now(), 'ended_at' => null, 'ended_by_user_id' => null],
            );
        });

        if ($match?->wasRecentlyCreated) {
            $this->notifyMatch($user->id, $requester->id, $match);
        }

        return ApiResponse::success([
            'decision' => $validated['decision'],
            'matched' => $match !== null,
            'match_id' => $match?->public_id,
        ], $validated['decision'] === 'accept' ? 'Like accepted successfully.' : 'Like declined successfully.');
    }

    public function withdraw(Request $request, string $profile): JsonResponse
    {
        $target = UserProfile::query()->where('public_id', $profile)->first();
        if ($target === null) {
            return ApiResponse::error('LIKE_REQUEST_NOT_FOUND', 'Pending like request not found.', 404);
        }

        $ids = [$request->user()->id, $target->user_id];
        sort($ids);
        $matched = UserMatch::query()->where('first_user_id', $ids[0])->where('second_user_id', $ids[1])
            ->where('status', 'active')->exists();
        if ($matched) {
            return ApiResponse::error('LIKE_ALREADY_MATCHED', 'An active match cannot be withdrawn as a like.', 409);
        }

        ProfileDecision::query()->where([
            'actor_user_id' => $request->user()->id,
            'target_user_id' => $target->user_id,
            'decision' => 'like',
        ])->delete();

        return ApiResponse::success(['withdrawn' => true], 'Like withdrawn successfully.');
    }

    private function availableRequester(User $user, string $profile): ?User
    {
        return User::query()->where('status', User::STATUS_ACTIVE)
            ->whereHas('profile', fn ($query) => $query->where('public_id', $profile)->where('profile_status', ProfileStatus::Live->value))
            ->whereExists(fn ($query) => $query->selectRaw('1')->from('profile_decisions')
                ->whereColumn('actor_user_id', 'users.id')->where('target_user_id', $user->id)->where('decision', 'like'))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('profile_decisions')
                ->where('actor_user_id', $user->id)->whereColumn('target_user_id', 'users.id'))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('user_blocks')
                ->where(fn ($block) => $block->whereColumn('blocker_user_id', 'users.id')->where('blocked_user_id', $user->id))
                ->orWhere(fn ($block) => $block->where('blocker_user_id', $user->id)->whereColumn('blocked_user_id', 'users.id')))
            ->first();
    }

    private function notifyMatch(int $firstId, int $secondId, UserMatch $match): void
    {
        foreach ([$firstId, $secondId] as $userId) {
            $this->notifier->send($userId, 'new_match', ['match_id' => $match->public_id], 'new_matches', 'match:'.$match->public_id);
        }
    }
}
