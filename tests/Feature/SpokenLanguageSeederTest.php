<?php

namespace Tests\Feature;

use Database\Seeders\SpokenLanguageSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SpokenLanguageSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeder_creates_active_language_catalog_idempotently(): void
    {
        $this->seed(SpokenLanguageSeeder::class);
        $this->seed(SpokenLanguageSeeder::class);

        $this->assertDatabaseCount('spoken_languages', 13);
        $this->assertDatabaseHas('spoken_languages', [
            'code' => 'ur',
            'name' => 'Urdu',
            'native_name' => 'اردو',
            'is_active' => true,
            'sort_order' => 20,
        ]);
    }
}
