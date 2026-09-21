<?php

namespace Tests\Feature;

use Database\Seeders\DatabaseSeeder;
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

        $this->assertDatabaseCount('spoken_languages', 36);
        $this->assertDatabaseHas('spoken_languages', [
            'code' => 'ur',
            'name' => 'Urdu',
            'native_name' => 'Urdu',
            'is_active' => true,
            'sort_order' => 20,
        ]);
    }

    public function test_database_seeder_populates_stable_catalogs_without_creating_fake_members(): void
    {
        $this->seed(DatabaseSeeder::class);

        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('spoken_languages', 36);
        $this->assertDatabaseCount('profile_catalog_items', 20);
        $this->assertDatabaseCount('help_categories', 6);
        $this->assertDatabaseCount('religion_taxonomy_nodes', 16);
    }


}
