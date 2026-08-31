<?php

namespace Database\Factories;

use App\Enums\Profile\Gender;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserProfile>
 */
class UserProfileFactory extends Factory
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
            'first_name' => fake()->firstName(),
            'date_of_birth' => fake()->dateTimeBetween('-55 years', '-18 years'),
            'gender' => fake()->randomElement(Gender::cases()),
            'city_name' => fake()->city(),
            'country_code' => fake()->countryCode(),
            'nationality_country_code' => fake()->countryCode(),
            'marital_status' => 'single',
            'profession_status' => 'employed',
            'smoking' => 'no',
            'alcohol' => 'no',
            'current_children' => 'none',
            'future_children' => 'open_to_children',
        ];
    }
}
