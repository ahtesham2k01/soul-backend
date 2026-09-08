<?php

namespace Database\Seeders;

use App\Models\HelpCategory;
use App\Models\ProfileCatalogItem;
use Illuminate\Database\Seeder;

class ProfileAndSupportCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $catalogs = [
            'interest' => [
                'reading' => ['Reading', 'Kitabein parhna'], 'travel' => ['Travel', 'Safar'],
                'cooking' => ['Cooking', 'Khana pakana'], 'fitness' => ['Fitness', 'Fitness'],
                'music' => ['Music', 'Music'], 'movies' => ['Movies', 'Filmein'],
                'sports' => ['Sports', 'Khel'], 'gaming' => ['Gaming', 'Gaming'],
                'photography' => ['Photography', 'Photography'], 'nature' => ['Nature', 'Qudrat'],
                'volunteering' => ['Volunteering', 'Khidmat-e-khalq'], 'technology' => ['Technology', 'Technology'],
            ],
            'trait' => [
                'kind' => ['Kind', 'Meharban'], 'curious' => ['Curious', 'Janne ka shoq'],
                'honest' => ['Honest', 'Imaandar'], 'calm' => ['Calm', 'Pur-sukoon'],
                'ambitious' => ['Ambitious', 'Pur-azm'], 'funny' => ['Funny', 'Mazahiya'],
                'empathetic' => ['Empathetic', 'Hamdard'], 'adventurous' => ['Adventurous', 'Jurratmand'],
            ],
        ];

        foreach ($catalogs as $type => $items) {
            foreach ($items as $order => $labels) {
                $item = ProfileCatalogItem::updateOrCreate(
                    ['type' => $type, 'key' => $order],
                    ['is_active' => true, 'sort_order' => array_search($order, array_keys($items), true)],
                );
                $item->translations()->updateOrCreate(['locale' => 'en'], ['label' => $labels[0]]);
                $item->translations()->updateOrCreate(['locale' => 'ur'], ['label' => $labels[1]]);
            }
        }

        $help = [
            'account' => ['Account & login', 'Account aur login'],
            'profile' => ['Profile & photos', 'Profile aur photos'],
            'matching' => ['Matching & chat', 'Matching aur chat'],
            'safety' => ['Safety & reporting', 'Safety aur reporting'],
            'payments' => ['Plans & payments', 'Plans aur payments'],
            'technical' => ['Technical problem', 'Technical masla'],
        ];
        foreach ($help as $order => $labels) {
            $category = HelpCategory::updateOrCreate(
                ['key' => $order],
                ['is_active' => true, 'sort_order' => array_search($order, array_keys($help), true)],
            );
            $category->translations()->updateOrCreate(['locale' => 'en'], ['name' => $labels[0]]);
            $category->translations()->updateOrCreate(['locale' => 'ur'], ['name' => $labels[1]]);
        }
    }
}
