<?php

namespace App\Http\Controllers\Api\V1\Webhooks;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\ProfilePhoto;
use App\Support\Media\CloudinaryUploadVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CloudinaryModerationController extends Controller
{
    public function __invoke(
        Request $request,
        CloudinaryUploadVerifier $verifier,
    ): JsonResponse {
        $timestamp = (int) $request->header('X-Cld-Timestamp');
        $signature = (string) $request->header('X-Cld-Signature');

        if (! $verifier->verifyNotification(
            $request->getContent(),
            $timestamp,
            $signature,
        )) {
            return response()->json(['accepted' => false], 401);
        }

        $validated = Validator::make($request->json()->all(), [
            'public_id' => ['required', 'string', 'max:255'],
            'moderation_status' => ['required', 'in:approved,rejected'],
            'moderation_kind' => ['nullable', 'string', 'max:50'],
            'face_detected' => ['sometimes', 'boolean'],
        ])->validate();

        $photo = ProfilePhoto::query()
            ->where('storage_provider', 'cloudinary')
            ->where('provider_asset_id', $validated['public_id'])
            ->first();

        if ($photo !== null) {
            $status = ProfilePhotoModerationStatus::from(
                $validated['moderation_status'],
            );
            $photo->update([
                'moderation_status' => $status,
                'rejection_reason' => $status === ProfilePhotoModerationStatus::Rejected
                    ? $this->rejectionReason($validated['moderation_kind'] ?? null)
                    : null,
                'face_detected' => $validated['face_detected']
                    ?? $photo->face_detected,
            ]);

            if ($status === ProfilePhotoModerationStatus::Rejected) {
                $photo->userProfile->update([
                    'profile_status' => ProfileStatus::ChangesRequired,
                    'status_reason' => $this->rejectionReason(
                        $validated['moderation_kind'] ?? null,
                    ),
                    'correction_screen' => 'onboarding.photos',
                ]);
            }
        }

        return response()->json(['accepted' => true]);
    }

    private function rejectionReason(?string $moderationKind): string
    {
        return match ($moderationKind) {
            'aws_rek', 'webpurify' => 'Photo contains content that is not allowed.',
            'duplicate' => 'Photo appears to duplicate another uploaded image.',
            'manual' => 'Photo did not meet the profile photo guidelines.',
            default => 'Photo did not pass automated moderation.',
        };
    }
}
