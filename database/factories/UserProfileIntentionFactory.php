<?php

namespace Database\Factories;

use App\Enums\Profile\RelationshipIntention;
use App\Models\UserProfile;
use App\Models\UserProfileIntention;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserProfileIntention>
 */
class UserProfileIntentionFactory extends Factory
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
            'intention' => fake()->randomElement(
                RelationshipIntention::cases(),
            ),
        ];
    }
}
