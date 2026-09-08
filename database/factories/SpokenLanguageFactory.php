<?php

namespace Database\Factories;

use App\Models\SpokenLanguage;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SpokenLanguage>
 */
class SpokenLanguageFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'code' => fake()->unique()->languageCode(),
            'name' => fake()->languageCode(),
            'native_name' => fake()->languageCode(),
            'is_active' => true,
        ];
    }
}
