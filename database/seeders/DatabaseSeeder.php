<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed stable application catalogs only.
     *
     * Real members and operator accounts are never created implicitly.
     */
    public function run(): void
    {
        $this->call([
            SpokenLanguageSeeder::class,
            ProfileAndSupportCatalogSeeder::class,
        ]);
    }
}
