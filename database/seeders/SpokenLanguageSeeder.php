<?php

namespace Database\Seeders;

use App\Models\SpokenLanguage;
use Illuminate\Database\Seeder;

class SpokenLanguageSeeder extends Seeder
{
    /**
     * Seed a broad, globally useful spoken-language baseline.
     *
     * Existing rows are never overwritten so admin visibility/order changes
     * survive future deploys and db:seed runs.
     */
    public function run(): void
    {
        $languages = [
            ['en', 'English', 'English'],
            ['ur', 'Urdu', 'Urdu'],
            ['ar', 'Arabic', 'العربية'],
            ['fa', 'Persian', 'فارسی'],
            ['he', 'Hebrew', 'עברית'],
            ['hi', 'Hindi', 'हिन्दी'],
            ['bn', 'Bengali', 'বাংলা'],
            ['pa', 'Punjabi', 'ਪੰਜਾਬੀ'],
            ['gu', 'Gujarati', 'ગુજરાતી'],
            ['mr', 'Marathi', 'मराठी'],
            ['ta', 'Tamil', 'தமிழ்'],
            ['te', 'Telugu', 'తెలుగు'],
            ['ml', 'Malayalam', 'മലയാളം'],
            ['kn', 'Kannada', 'ಕನ್ನಡ'],
            ['ne', 'Nepali', 'नेपाली'],
            ['ps', 'Pashto', 'پښتو'],
            ['sd', 'Sindhi', 'سنڌي'],
            ['zh', 'Chinese', '中文'],
            ['ja', 'Japanese', '日本語'],
            ['ko', 'Korean', '한국어'],
            ['id', 'Indonesian', 'Bahasa Indonesia'],
            ['ms', 'Malay', 'Bahasa Melayu'],
            ['fil', 'Filipino', 'Filipino'],
            ['vi', 'Vietnamese', 'Tiếng Việt'],
            ['th', 'Thai', 'ไทย'],
            ['tr', 'Turkish', 'Türkçe'],
            ['es', 'Spanish', 'Español'],
            ['fr', 'French', 'Français'],
            ['de', 'German', 'Deutsch'],
            ['it', 'Italian', 'Italiano'],
            ['pt', 'Portuguese', 'Português'],
            ['nl', 'Dutch', 'Nederlands'],
            ['pl', 'Polish', 'Polski'],
            ['ru', 'Russian', 'Русский'],
            ['uk', 'Ukrainian', 'Українська'],
            ['sw', 'Swahili', 'Kiswahili'],
        ];

        foreach ($languages as $index => [$code, $name, $nativeName]) {
            SpokenLanguage::query()->firstOrCreate(
                ['code' => $code],
                [
                    'name' => $name,
                    'native_name' => $nativeName,
                    'sort_order' => ($index + 1) * 10,
                    'is_active' => true,
                ],
            );
        }
    }
}
