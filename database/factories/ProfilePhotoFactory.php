<?php

namespace Database\Factories;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Models\ProfilePhoto;
use App\Models\UserProfile;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfilePhoto>
 */
class ProfilePhotoFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_profile_id' => UserProfile::factory(),
            'position' => 1,
            'visibility' => ProfilePhotoVisibility::Public,
            'storage_provider' => 'cloudinary',
            'provider_asset_id' => fake()->unique()->uuid(),
            'moderation_status' => ProfilePhotoModerationStatus::Pending,
            'face_detected' => null,
            'screenshot_protection_enabled' => true,
        ];
    }
}
