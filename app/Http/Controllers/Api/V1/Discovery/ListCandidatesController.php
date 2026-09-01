<?php

namespace App\Http\Controllers\Api\V1\Discovery;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ListCandidatesController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $viewer = $user->profile()->first();
        $preference = $user->discoveryPreference;

        if ($viewer?->profile_status !== ProfileStatus::Live || $preference === null) {
            return ApiResponse::error(
                code: 'DISCOVERY_NOT_READY',
                message: 'Complete your live profile and discovery preferences first.',
                status: 409,
            );
        }

        $oldest = now()->subYears($preference->maximum_age + 1)->addDay()->toDateString();
        $youngest = now()->subYears($preference->minimum_age)->toDateString();
        $query = UserProfile::query()
            ->where('user_id', '!=', $user->id)
            ->where('profile_status', ProfileStatus::Live->value)
            ->where('gender', $preference->preferred_gender->value)
            ->whereBetween('date_of_birth', [$oldest, $youngest])
            ->whereHas('user', fn ($query) => $query->where('status', User::STATUS_ACTIVE))
            ->whereDoesntHave('user.privacySetting', fn ($query) => $query->where('discoverable', false))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')
                ->from('profile_decisions')
                ->where('actor_user_id', $user->id)
                ->whereColumn('target_user_id', 'user_profiles.user_id'))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('user_blocks')
                ->where(fn ($query) => $query
                    ->whereColumn('blocker_user_id', 'user_profiles.user_id')
                    ->where('blocked_user_id', $user->id))
                ->orWhere(fn ($query) => $query
                    ->where('blocker_user_id', $user->id)
                    ->whereColumn('blocked_user_id', 'user_profiles.user_id')));

        if ($preference->same_country_only) {
            $query->where('country_code', $viewer->country_code);
        }

        $page = $query->with(['user.privacySetting', 'photos' => fn ($query) => $query
            ->where('visibility', ProfilePhotoVisibility::Public->value)
            ->where('moderation_status', ProfilePhotoModerationStatus::Approved->value)])
            ->orderByDesc('id')->cursorPaginate(20);

        return ApiResponse::success([
            'candidates' => collect($page->items())->map(fn (UserProfile $profile): array => [
                'id' => $profile->public_id,
                'first_name' => $profile->first_name,
                'age' => $profile->user->privacySetting?->show_age === false ? null : $profile->date_of_birth->age,
                'city' => $profile->user->privacySetting?->show_city === false ? null : $profile->city_name,
                'country' => $profile->country_code,
                'photos' => $profile->photos->map(fn ($photo): array => [
                    'id' => $photo->public_id,
                    'position' => $photo->position,
                ])->values(),
            ])->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
