<?php

namespace App\Http\Controllers\Api\V1\Discovery;

use App\Enums\Profile\DiscoveryLocationMode;
use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Enums\Profile\ProfileStatus;
use App\Enums\Profile\ReligionDiscoveryMode;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use App\Support\Discovery\DistanceBand;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ListCandidatesController extends Controller
{
    public function __invoke(Request $request, DistanceBand $distanceBand): JsonResponse
    {
        $user = $request->user();
        $viewer = $user->profile()->first();
        $preference = $user->discoveryPreference;
        $viewerPrivacy = $user->privacySetting;

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
            ->whereDoesntHave('user.privacySetting', fn ($query) => $query->where('profile_paused', true))
            ->where('last_active_at', '>=', now()->subDays(90))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')
                ->from('profile_decisions')
                ->where('actor_user_id', $user->id)
                ->whereColumn('target_user_id', 'user_profiles.user_id')
                ->where(fn ($decision) => $decision
                    ->where('decision', 'like')
                    ->orWhere(fn ($pass) => $pass
                        ->where('decision', 'pass')
                        ->where('updated_at', '>', now()->subDays(30)))))
            ->whereNotExists(fn ($query) => $query->selectRaw('1')->from('user_blocks')
                ->where(fn ($query) => $query
                    ->whereColumn('blocker_user_id', 'user_profiles.user_id')
                    ->where('blocked_user_id', $user->id))
                ->orWhere(fn ($query) => $query
                    ->where('blocker_user_id', $user->id)
                    ->whereColumn('blocked_user_id', 'user_profiles.user_id')));

        $query->where(function ($visible) use ($user): void {
            $visible->whereDoesntHave('user.privacySetting', fn ($privacy) => $privacy->where('incognito', true))
                ->orWhereExists(fn ($decision) => $decision->selectRaw('1')->from('profile_decisions')
                    ->whereColumn('actor_user_id', 'user_profiles.user_id')
                    ->where('target_user_id', $user->id)
                    ->where('decision', 'like'));
        });

        if ($viewerPrivacy?->hide_contacts) {
            $query->whereNotExists(fn ($contacts) => $contacts->selectRaw('1')->from('hidden_contact_hashes')
                ->join('users as contact_users', 'contact_users.phone_lookup_hash', '=', 'hidden_contact_hashes.phone_hash')
                ->where('hidden_contact_hashes.user_id', $user->id)
                ->whereColumn('contact_users.id', 'user_profiles.user_id'));
        }

        if ($preference->same_country_only) {
            $query->where('country_code', $viewer->country_code);
        }

        if ($preference->intentions->isNotEmpty()) {
            $query->whereHas('intentions', fn ($intentions) => $intentions
                ->whereIn('intention', $preference->intentions->pluck('intention')->map->value));
        }

        if ($preference->location_mode === DiscoveryLocationMode::Selected) {
            $query->where(function ($locations) use ($preference): void {
                foreach ($preference->locations as $location) {
                    $locations->orWhere(function ($item) use ($location): void {
                        $item->where('country_code', $location->country_code);
                        if ($location->city_name !== null) {
                            $item->where('city_name', $location->city_name);
                        }
                    });
                }
            });
        }

        if ($preference->radius_km !== null) {
            if ($viewer->latitude === null || $viewer->longitude === null) {
                return ApiResponse::error('DISCOVERY_LOCATION_REQUIRED', 'Save your current location before using a radius filter.', 409);
            }
            $latitudeDelta = $preference->radius_km / 111;
            $longitudeDelta = $preference->radius_km / max(1, 111 * cos(deg2rad((float) $viewer->latitude)));
            $query->whereBetween('latitude', [(float) $viewer->latitude - $latitudeDelta, (float) $viewer->latitude + $latitudeDelta])
                ->whereBetween('longitude', [(float) $viewer->longitude - $longitudeDelta, (float) $viewer->longitude + $longitudeDelta]);
        }

        if ($preference->religion_mode === ReligionDiscoveryMode::MyReligion) {
            $rootNodeId = $user->religionProfile?->root_node_id;

            if ($rootNodeId === null) {
                return ApiResponse::error(
                    code: 'DISCOVERY_RELIGION_REQUIRED',
                    message: 'Complete your religion selection before using My Religion discovery.',
                    status: 409,
                );
            }

            $query->whereHas('user.religionProfile', fn ($religion) => $religion
                ->where('root_node_id', $rootNodeId));
        }

        $page = $query->with(['user.privacySetting', 'user.religionProfile.rootNode', 'photos' => fn ($query) => $query
            ->where('visibility', ProfilePhotoVisibility::Public->value)
            ->where('moderation_status', ProfilePhotoModerationStatus::Approved->value)])
            ->orderByRaw('CASE WHEN last_active_at >= ? THEN 0 ELSE 1 END', [now()->subDays(30)])
            ->orderByDesc('last_active_at')->orderByDesc('id')->cursorPaginate(20);

        return ApiResponse::success([
            'candidates' => collect($page->items())->filter(function (UserProfile $profile) use ($viewer, $preference, $distanceBand): bool {
                if ($preference->radius_km === null) {
                    return true;
                }

                return $profile->latitude !== null && $profile->longitude !== null
                    && $distanceBand->kilometres((float) $viewer->latitude, (float) $viewer->longitude, (float) $profile->latitude, (float) $profile->longitude) <= $preference->radius_km;
            })->map(fn (UserProfile $profile): array => [
                'id' => $profile->public_id,
                'first_name' => $profile->first_name,
                'age' => $profile->date_of_birth->age,
                'city' => $profile->user->privacySetting?->show_city === false ? null : $profile->city_name,
                'country' => $profile->country_code,
                'religion' => $profile->user->religionProfile?->rootNode === null ? null : [
                    'id' => $profile->user->religionProfile->rootNode->public_id,
                    'slug' => $profile->user->religionProfile->rootNode->slug,
                ],
                'distance_band' => $viewer->latitude === null || $viewer->longitude === null || $profile->latitude === null || $profile->longitude === null
                    ? null : $distanceBand->label($distanceBand->kilometres((float) $viewer->latitude, (float) $viewer->longitude, (float) $profile->latitude, (float) $profile->longitude)),
                'photos' => $profile->photos->map(fn ($photo): array => [
                    'id' => $photo->public_id,
                    'position' => $photo->position,
                ])->values(),
            ])->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
