<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Enums\Profile\ProfilePhotoVisibility;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProfilePhotoResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class UpdateProfilePhotoVisibilityController extends Controller
{
    public function __invoke(Request $request, int $position): JsonResponse
    {
        if ($position < 1 || $position > 3) {
            throw ValidationException::withMessages([
                'position' => ['The position must be between 1 and 3.'],
            ]);
        }

        $validated = $request->validate([
            'visibility' => [
                'required',
                Rule::enum(ProfilePhotoVisibility::class),
            ],
        ]);
        $visibility = ProfilePhotoVisibility::from($validated['visibility']);

        if ($position === 1 && $visibility !== ProfilePhotoVisibility::Public) {
            throw ValidationException::withMessages([
                'visibility' => ['The cover photo must remain public.'],
            ]);
        }

        $photo = $request->user()->profile?->photos()
            ->where('position', $position)
            ->first();

        if ($photo === null) {
            return ApiResponse::error(
                'PROFILE_PHOTO_NOT_FOUND',
                'Profile photo not found.',
                404,
            );
        }

        if (
            $visibility === ProfilePhotoVisibility::Private
            && $photo->delivery_type !== 'authenticated'
        ) {
            return ApiResponse::error(
                'PRIVATE_PHOTO_REUPLOAD_REQUIRED',
                'This photo must be replaced before it can be made private.',
                409,
            );
        }

        $photo->update(['visibility' => $visibility->value]);

        return ApiResponse::success([
            'photo' => (new ProfilePhotoResource($photo->refresh()))
                ->resolve($request),
        ], 'Photo visibility updated successfully.');
    }
}
