<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\RegisterProfilePhotoRequest;
use App\Http\Resources\Api\V1\ProfilePhotoResource;
use App\Jobs\DestroyCloudinaryAsset;
use App\Models\ProfilePhoto;
use App\Models\ProfilePhotoUpload;
use App\Support\ApiResponse;
use App\Support\Media\CloudinaryUploadVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RegisterProfilePhotoController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(
        RegisterProfilePhotoRequest $request,
        int $position,
        CloudinaryUploadVerifier $verifier,
    ): JsonResponse {
        if (! $verifier->isConfigured()) {
            return ApiResponse::error(
                code: 'MEDIA_PROVIDER_UNAVAILABLE',
                message: 'Photo uploads are temporarily unavailable.',
                status: 503,
            );
        }

        $validated = $request->validated();
        if (! $verifier->verify(
            $validated['provider_asset_id'],
            $validated['provider_version'],
            $validated['provider_signature'],
        )) {
            throw ValidationException::withMessages([
                'provider_signature' => [
                    'The upload proof could not be verified.',
                ],
            ]);
        }

        $profile = $request->user()->profile;
        if ($profile === null) {
            return ApiResponse::error(
                code: 'PROFILE_NOT_STARTED',
                message: 'Start the profile draft before adding photos.',
                status: 409,
            );
        }

        $photo = DB::transaction(function () use (
            $request,
            $profile,
            $position,
            $validated,
        ): ProfilePhoto {
            $upload = ProfilePhotoUpload::query()
                ->where('public_id', $validated['upload_token'])
                ->where('user_id', $request->user()->getKey())
                ->lockForUpdate()
                ->first();

            if (
                $upload === null
                || $upload->position !== $position
                || $upload->provider_asset_id !== $validated['provider_asset_id']
                || ($upload->consumed_at === null && $upload->expires_at->isPast())
            ) {
                throw ValidationException::withMessages([
                    'upload_token' => ['The upload session is invalid or expired.'],
                ]);
            }

            $existing = $profile->photos()
                ->where('position', $position)
                ->lockForUpdate()
                ->first();

            if ($upload->consumed_at !== null) {
                if ($existing?->provider_asset_id !== $validated['provider_asset_id']) {
                    throw ValidationException::withMessages([
                        'upload_token' => ['This upload session has already been used.'],
                    ]);
                }

                $existing->update(['visibility' => $validated['visibility']]);

                return $existing->refresh();
            }

            $assetAlreadyUsed = ProfilePhoto::query()
                ->where('storage_provider', 'cloudinary')
                ->where('provider_asset_id', $validated['provider_asset_id'])
                ->when(
                    $existing !== null,
                    fn ($query) => $query->whereKeyNot($existing->getKey()),
                )
                ->exists();

            if ($assetAlreadyUsed) {
                throw ValidationException::withMessages([
                    'provider_asset_id' => [
                        'This uploaded asset is already registered.',
                    ],
                ]);
            }

            if ($existing?->provider_asset_id === $validated['provider_asset_id']) {
                $existing->update(['visibility' => $validated['visibility']]);
                $upload->update(['consumed_at' => now()]);

                return $existing->refresh();
            }

            $attributes = [
                'position' => $position,
                'visibility' => $validated['visibility'],
                'storage_provider' => 'cloudinary',
                'provider_asset_id' => $validated['provider_asset_id'],
                'moderation_status' => ProfilePhotoModerationStatus::Pending,
                'rejection_reason' => null,
                'face_detected' => null,
                'screenshot_protection_enabled' => true,
            ];

            if ($existing === null) {
                $photo = $profile->photos()->create($attributes);
                $upload->update(['consumed_at' => now()]);

                return $photo;
            }

            $replacedProviderAssetId = $existing->provider_asset_id;
            $existing->update($attributes);
            $upload->update(['consumed_at' => now()]);
            DB::afterCommit(
                fn () => DestroyCloudinaryAsset::dispatch(
                    $replacedProviderAssetId,
                ),
            );

            return $existing->refresh();
        });

        return ApiResponse::success(
            data: [
                'photo' => (new ProfilePhotoResource($photo))->resolve($request),
            ],
            message: 'Profile photo registered successfully.',
        );
    }
}
