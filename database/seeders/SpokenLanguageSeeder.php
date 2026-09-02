<?php

namespace Database\Seeders;

use App\Models\SpokenLanguage;
use Illuminate\Database\Seeder;

class SpokenLanguageSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        SpokenLanguage::query()->upsert([
            ['code' => 'en', 'name' => 'English', 'native_name' => 'English', 'sort_order' => 10, 'is_active' => true],
            ['code' => 'ur', 'name' => 'Urdu', 'native_name' => 'اردو', 'sort_order' => 20, 'is_active' => true],
            ['code' => 'ar', 'name' => 'Arabic', 'native_name' => 'العربية', 'sort_order' => 30, 'is_active' => true],
            ['code' => 'hi', 'name' => 'Hindi', 'native_name' => 'हिन्दी', 'sort_order' => 40, 'is_active' => true],
            ['code' => 'bn', 'name' => 'Bengali', 'native_name' => 'বাংলা', 'sort_order' => 50, 'is_active' => true],
            ['code' => 'pa', 'name' => 'Punjabi', 'native_name' => 'ਪੰਜਾਬੀ', 'sort_order' => 60, 'is_active' => true],
            ['code' => 'es', 'name' => 'Spanish', 'native_name' => 'Español', 'sort_order' => 70, 'is_active' => true],
            ['code' => 'fr', 'name' => 'French', 'native_name' => 'Français', 'sort_order' => 80, 'is_active' => true],
            ['code' => 'de', 'name' => 'German', 'native_name' => 'Deutsch', 'sort_order' => 90, 'is_active' => true],
            ['code' => 'pt', 'name' => 'Portuguese', 'native_name' => 'Português', 'sort_order' => 100, 'is_active' => true],
            ['code' => 'tr', 'name' => 'Turkish', 'native_name' => 'Türkçe', 'sort_order' => 110, 'is_active' => true],
            ['code' => 'fa', 'name' => 'Persian', 'native_name' => 'فارسی', 'sort_order' => 120, 'is_active' => true],
            ['code' => 'id', 'name' => 'Indonesian', 'native_name' => 'Bahasa Indonesia', 'sort_order' => 130, 'is_active' => true],
        ], ['code'], [
            'name',
            'native_name',
            'sort_order',
            'is_active',
        ]);
    }
}
