<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\CreateProfilePhotoUploadRequest;
use App\Models\ProfilePhotoUpload;
use App\Support\ApiResponse;
use App\Support\Media\CloudinaryUploadVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CreateProfilePhotoUploadController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(
        CreateProfilePhotoUploadRequest $request,
        CloudinaryUploadVerifier $verifier,
    ): JsonResponse {
        if (! $verifier->canSignUploads()) {
            return ApiResponse::error(
                code: 'MEDIA_PROVIDER_UNAVAILABLE',
                message: 'Photo uploads are temporarily unavailable.',
                status: 503,
            );
        }

        $user = $request->user();
        if (! $user->profile()->exists()) {
            return ApiResponse::error(
                code: 'PROFILE_NOT_STARTED',
                message: 'Start the profile draft before adding photos.',
                status: 409,
            );
        }

        $position = $request->integer('position');
        $timestamp = now()->timestamp;
        $ttlMinutes = max(1, min(
            30,
            (int) config(
                'soul.media.cloudinary.upload_session_ttl_minutes',
                10,
            ),
        ));
        $expiresAt = now()->addMinutes($ttlMinutes);
        $providerAssetId = sprintf(
            'soul/profile-photos/%s/%s',
            $user->public_id,
            Str::ulid(),
        );

        $upload = DB::transaction(function () use (
            $user,
            $position,
            $providerAssetId,
            $expiresAt,
        ): ProfilePhotoUpload {
            $user->profilePhotoUploads()
                ->where('position', $position)
                ->whereNull('consumed_at')
                ->where('expires_at', '>', now())
                ->update(['expires_at' => now()]);

            return $user->profilePhotoUploads()->create([
                'position' => $position,
                'provider_asset_id' => $providerAssetId,
                'expires_at' => $expiresAt,
            ]);
        });

        $cloudName = (string) config('soul.media.cloudinary.cloud_name');

        return ApiResponse::success(
            data: [
                'upload' => [
                    'token' => $upload->public_id,
                    'position' => $upload->position,
                    'expires_at' => $upload->expires_at->toIso8601String(),
                    'url' => sprintf(
                        'https://api.cloudinary.com/v1_1/%s/image/upload',
                        rawurlencode($cloudName),
                    ),
                    'parameters' => [
                        'api_key' => (string) config('soul.media.cloudinary.api_key'),
                        'timestamp' => $timestamp,
                        'public_id' => $providerAssetId,
                        'signature' => $verifier->signUpload(
                            $providerAssetId,
                            $timestamp,
                        ),
                    ],
                ],
            ],
            message: 'Photo upload session created successfully.',
        );
    }
}
