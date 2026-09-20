<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Http\Controllers\Controller;
use App\Models\UserBlock;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use App\Support\Media\CloudinaryDeliveryUrl;
use App\Support\Safety\CloseUserInteraction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BlockUserController extends Controller
{
    public function index(Request $request, CloudinaryDeliveryUrl $deliveryUrl): JsonResponse
    {
        $page = UserBlock::query()
            ->where('blocker_user_id', $request->user()->id)
            ->with([
                'blockedUser.profile.photos' => fn ($query) => $query
                    ->where('visibility', ProfilePhotoVisibility::Public->value)
                    ->where('moderation_status', ProfilePhotoModerationStatus::Approved->value)
                    ->orderBy('position'),
            ])
            ->latest('id')
            ->cursorPaginate(30);

        return ApiResponse::success([
            'blocks' => collect($page->items())->map(function (UserBlock $block) use ($deliveryUrl): array {
                $profile = $block->blockedUser?->profile;
                $photo = $profile?->photos->first();

                return [
                    'profile' => [
                        'id' => $profile?->public_id,
                        'first_name' => $profile?->first_name,
                        'photo' => $photo === null ? null : [
                            'id' => $photo->public_id,
                            'position' => $photo->position,
                            'url' => $photo->format === null || ! filled(config('soul.media.cloudinary.cloud_name'))
                                ? null
                                : $deliveryUrl->forProfileImage(
                                    $photo->provider_asset_id,
                                    $photo->format,
                                    $photo->delivery_type,
                                ),
                        ],
                    ],
                    'blocked_at' => $block->created_at->toIso8601String(),
                ];
            })->filter(fn (array $item): bool => filled($item['profile']['id']))->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function __invoke(Request $request, string $profile, CloseUserInteraction $closer): JsonResponse
    {
        $validated = $request->validate(['reason' => ['nullable', 'string', 'max:500']]);
        $target = UserProfile::query()->where('public_id', $profile)->first();

        if ($target === null || $target->user_id === $request->user()->id) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'Profile unavailable.', 404);
        }

        DB::transaction(
            fn () => $closer->block(
                $request->user()->id,
                $target->user_id,
                $validated['reason'] ?? null,
            ),
        );

        return ApiResponse::success(['blocked' => true], 'User blocked successfully.');
    }

    public function destroy(Request $request, string $profile): JsonResponse
    {
        $target = UserProfile::query()->where('public_id', $profile)->first();

        if ($target === null) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'Profile unavailable.', 404);
        }

        UserBlock::query()
            ->where('blocker_user_id', $request->user()->id)
            ->where('blocked_user_id', $target->user_id)
            ->delete();

        return ApiResponse::success(['blocked' => false], 'User unblocked successfully.');
    }
}
