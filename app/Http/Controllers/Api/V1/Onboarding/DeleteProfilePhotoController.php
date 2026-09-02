<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Jobs\DestroyCloudinaryAsset;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class DeleteProfilePhotoController extends Controller
{
    public function __invoke(Request $request, int $position): JsonResponse
    {
        if ($position < 1 || $position > 3) {
            throw ValidationException::withMessages([
                'position' => ['The position must be between 1 and 3.'],
            ]);
        }

        $profile = $request->user()->profile;
        if ($profile === null) {
            return ApiResponse::success(
                message: 'Profile photo removed successfully.',
            );
        }

        DB::transaction(function () use ($profile, $position): void {
            $photo = $profile->photos()
                ->where('position', $position)
                ->lockForUpdate()
                ->first();

            if ($photo === null) {
                return;
            }

            $providerAssetId = $photo->provider_asset_id;
            $photo->delete();

            DB::afterCommit(
                fn () => DestroyCloudinaryAsset::dispatch($providerAssetId),
            );
        });

        return ApiResponse::success(
            message: 'Profile photo removed successfully.',
        );
    }
}
