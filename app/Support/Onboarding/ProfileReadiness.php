<?php

namespace App\Support\Onboarding;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Models\User;

class ProfileReadiness
{
    /** @return array{is_ready: bool, missing_requirements: list<string>} */
    public function for(User $user): array
    {
        $profile = $user->profile()
            ->with(['intentions', 'spokenLanguages', 'photos'])
            ->first();

        if ($profile === null) {
            return [
                'is_ready' => false,
                'missing_requirements' => [
                    'profile', 'religion', 'cover_photo', 'clear_face_photo',
                ],
            ];
        }

        $requiredFields = [
            'first_name', 'date_of_birth', 'gender', 'city_name',
            'country_code', 'nationality_country_code', 'marital_status',
            'profession_status', 'smoking', 'alcohol',
            'current_children', 'future_children',
        ];
        $missing = collect($requiredFields)
            ->filter(fn (string $field): bool => blank($profile->{$field}))
            ->values();

        if ($profile->intentions->isEmpty()) {
            $missing->push('intentions');
        }
        if ($profile->spokenLanguages->isEmpty()) {
            $missing->push('spoken_languages');
        }
        if (! $user->religionProfile()->exists()) {
            $missing->push('religion');
        }

        $approvedPhotos = $profile->photos->where(
            'moderation_status', ProfilePhotoModerationStatus::Approved,
        );
        $hasCover = $approvedPhotos->contains(
            fn ($photo): bool => $photo->position === 1
                && $photo->visibility === ProfilePhotoVisibility::Public,
        );
        $hasClearFace = $approvedPhotos->contains(
            fn ($photo): bool => $photo->face_detected === true,
        );

        if (! $hasCover) {
            $missing->push('cover_photo');
        }
        if (! $hasClearFace) {
            $missing->push('clear_face_photo');
        }

        return [
            'is_ready' => $missing->isEmpty(),
            'missing_requirements' => $missing->all(),
        ];
    }
}
