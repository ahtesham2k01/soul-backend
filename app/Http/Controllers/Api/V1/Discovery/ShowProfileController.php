<?php

namespace App\Http\Controllers\Api\V1\Discovery;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\PublicUserProfileResource;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowProfileController extends Controller
{
    public function __invoke(Request $request, string $profile): JsonResponse
    {
        $viewer = $request->user();
        $record = UserProfile::query()
            ->where('public_id', $profile)
            ->where('user_id', '!=', $viewer->id)
            ->where('profile_status', ProfileStatus::Live->value)
            ->whereHas('user', fn ($query) => $query->where('status', User::STATUS_ACTIVE))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('user_blocks')
                ->where(fn ($block) => $block->whereColumn('blocker_user_id', 'user_profiles.user_id')->where('blocked_user_id', $viewer->id))
                ->orWhere(fn ($block) => $block->where('blocker_user_id', $viewer->id)->whereColumn('blocked_user_id', 'user_profiles.user_id')))
            ->where(function ($visible) use ($viewer): void {
                $visible->where(function ($public) use ($viewer): void {
                    $public->whereDoesntHave('user.privacySetting', fn ($privacy) => $privacy->where('discoverable', false)->orWhere('profile_paused', true))
                        ->where(function ($incognito) use ($viewer): void {
                            $incognito->whereDoesntHave('user.privacySetting', fn ($privacy) => $privacy->where('incognito', true))
                                ->orWhereExists(fn ($decision) => $decision->selectRaw('1')->from('profile_decisions')
                                    ->whereColumn('actor_user_id', 'user_profiles.user_id')
                                    ->where('target_user_id', $viewer->id)->where('decision', 'like'));
                        });
                })->orWhereExists(fn ($match) => $match->selectRaw('1')->from('user_matches')
                    ->where('status', 'active')
                    ->where(fn ($pair) => $pair
                        ->whereColumn('first_user_id', 'user_profiles.user_id')->where('second_user_id', $viewer->id)
                        ->orWhere(fn ($reverse) => $reverse->where('first_user_id', $viewer->id)->whereColumn('second_user_id', 'user_profiles.user_id'))));
            })
            ->with([
                'user.privacySetting', 'user.religionProfile.rootNode', 'user.religionProfile.selectedNode', 'user.verificationCases',
                'intentions', 'interests', 'personalityTraits', 'spokenLanguages', 'withheldFields',
                'photos' => fn ($query) => $query->where('visibility', ProfilePhotoVisibility::Public->value)
                    ->where('moderation_status', ProfilePhotoModerationStatus::Approved->value),
            ])->first();

        if ($record === null || (! $this->isMatched($viewer, $record) && $this->isHiddenContact($viewer, $record))) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'This profile is not available.', 404);
        }

        return ApiResponse::success(['profile' => new PublicUserProfileResource($record)]);
    }

    private function isHiddenContact(User $viewer, UserProfile $profile): bool
    {
        return (bool) ($viewer->privacySetting?->hide_contacts
            && $profile->user->phone_lookup_hash !== null
            && $viewer->hiddenContactHashes()->where('phone_hash', $profile->user->phone_lookup_hash)->exists());
    }

    private function isMatched(User $viewer, UserProfile $profile): bool
    {
        $ids = [$viewer->id, $profile->user_id];
        sort($ids);

        return UserMatch::query()->where('first_user_id', $ids[0])->where('second_user_id', $ids[1])
            ->where('status', 'active')->exists();
    }
}
