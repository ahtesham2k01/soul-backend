<?php

namespace Database\Factories;

use App\Models\ProfilePhotoUpload;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfilePhotoUpload>
 */
class ProfilePhotoUploadFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'position' => 1,
            'provider_asset_id' => 'soul/profile-photos/'.fake()->uuid(),
            'expires_at' => now()->addMinutes(10),
            'consumed_at' => null,
        ];
    }
}
