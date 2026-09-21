<?php

namespace Tests\Feature\Database;

use App\Models\HelpCategory;
use App\Models\ProfileCatalogItem;
use App\Models\ReligionTaxonomyNode;
use App\Models\SpokenLanguage;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StableCatalogSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_fresh_seed_provides_global_spoken_languages_and_neutral_religion_roots(): void
    {
        $this->seed(DatabaseSeeder::class);

        $this->assertGreaterThanOrEqual(30, SpokenLanguage::query()->count());
        $this->assertDatabaseHas('spoken_languages', [
            'code' => 'ur',
            'name' => 'Urdu',
            'native_name' => 'Urdu',
            'is_active' => true,
        ]);

        foreach (['islam', 'christianity', 'hinduism', 'buddhism', 'sikhism', 'judaism'] as $slug) {
            $this->assertDatabaseHas('religion_taxonomy_nodes', [
                'parent_id' => null,
                'slug' => $slug,
                'path' => $slug,
                'is_active' => true,
            ]);
        }

        $romanUrduLabels = ReligionTaxonomyNode::query()
            ->with('translations')
            ->get()
            ->flatMap(fn (ReligionTaxonomyNode $node) => $node->translations)
            ->where('locale', 'ur')
            ->pluck('label');

        $this->assertNotEmpty($romanUrduLabels);

        foreach ($romanUrduLabels as $label) {
            $this->assertDoesNotMatchRegularExpression('/[\x{0600}-\x{06FF}]/u', $label);
        }
    }

    public function test_reseeding_never_reactivates_or_overwrites_admin_managed_catalog_rows(): void
    {
        $this->seed(DatabaseSeeder::class);

        $language = SpokenLanguage::query()->where('code', 'en')->firstOrFail();
        $language->update([
            'native_name' => 'Operator English',
            'is_active' => false,
            'sort_order' => 999,
        ]);

        $interest = ProfileCatalogItem::query()
            ->where('type', 'interest')
            ->where('key', 'reading')
            ->firstOrFail();
        $interest->update(['is_active' => false, 'sort_order' => 999]);
        $interest->translations()->where('locale', 'en')->update(['label' => 'Operator Reading']);

        $help = HelpCategory::query()->where('key', 'account')->firstOrFail();
        $help->update(['is_active' => false, 'sort_order' => 999]);
        $help->translations()->where('locale', 'en')->update(['name' => 'Operator Account']);

        $religion = ReligionTaxonomyNode::query()->where('slug', 'islam')->firstOrFail();
        $religion->update(['is_active' => false, 'sort_order' => 999]);
        $religion->translations()->where('locale', 'en')->update(['label' => 'Operator Islam']);

        $this->seed(DatabaseSeeder::class);

        $this->assertDatabaseHas('spoken_languages', [
            'code' => 'en',
            'native_name' => 'Operator English',
            'is_active' => false,
            'sort_order' => 999,
        ]);
        $this->assertDatabaseHas('profile_catalog_items', [
            'type' => 'interest',
            'key' => 'reading',
            'is_active' => false,
            'sort_order' => 999,
        ]);
        $this->assertDatabaseHas('profile_catalog_item_translations', [
            'profile_catalog_item_id' => $interest->id,
            'locale' => 'en',
            'label' => 'Operator Reading',
        ]);
        $this->assertDatabaseHas('help_categories', [
            'key' => 'account',
            'is_active' => false,
            'sort_order' => 999,
        ]);
        $this->assertDatabaseHas('help_category_translations', [
            'help_category_id' => $help->id,
            'locale' => 'en',
            'name' => 'Operator Account',
        ]);
        $this->assertDatabaseHas('religion_taxonomy_nodes', [
            'id' => $religion->id,
            'is_active' => false,
            'sort_order' => 999,
        ]);
        $this->assertDatabaseHas('religion_taxonomy_translations', [
            'node_id' => $religion->id,
            'locale' => 'en',
            'label' => 'Operator Islam',
        ]);
    }
}
