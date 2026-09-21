<?php

namespace Database\Seeders;

use App\Enums\Profile\ReligionNodeType;
use App\Models\ReligionTaxonomyNode;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ReligionTaxonomySeeder extends Seeder
{
    /**
     * Seed neutral root-level religion/belief options only.
     *
     * Child sect/tradition/community trees remain admin-managed because
     * country and community requirements vary and should not be invented
     * by a deployment seed.
     */
    public function run(): void
    {
        $roots = [
            ['religion', 'islam', 'Islam', 'Islam'],
            ['religion', 'christianity', 'Christianity', 'Christianity'],
            ['religion', 'hinduism', 'Hinduism', 'Hinduism'],
            ['religion', 'buddhism', 'Buddhism', 'Buddhism'],
            ['religion', 'sikhism', 'Sikhism', 'Sikhism'],
            ['religion', 'judaism', 'Judaism', 'Judaism'],
            ['religion', 'jainism', 'Jainism', 'Jainism'],
            ['religion', 'bahai-faith', 'Baháʼí Faith', 'Bahai Faith'],
            ['religion', 'zoroastrianism', 'Zoroastrianism', 'Zoroastrianism'],
            ['religion', 'shinto', 'Shinto', 'Shinto'],
            ['religion', 'taoism', 'Taoism', 'Taoism'],
            ['religion', 'traditional-indigenous', 'Traditional / Indigenous beliefs', 'Riwayati / maqami aqeede'],
            ['belief', 'spiritual-not-religious', 'Spiritual, not religious', 'Rohani, magar mazhabi nahi'],
            ['belief', 'agnostic', 'Agnostic', 'Agnostic'],
            ['belief', 'atheist', 'Atheist', 'Atheist'],
            ['belief', 'other-belief', 'Other belief', 'Dusra aqeeda'],
        ];

        foreach ($roots as $index => [$type, $slug, $english, $romanUrdu]) {
            $node = ReligionTaxonomyNode::query()->firstOrCreate(
                [
                    'parent_id' => null,
                    'path' => $slug,
                ],
                [
                    'public_id' => (string) Str::ulid(),
                    'type' => ReligionNodeType::from($type),
                    'slug' => $slug,
                    'is_active' => true,
                    'sort_order' => ($index + 1) * 10,
                ],
            );

            $node->translations()->firstOrCreate(
                ['locale' => 'en'],
                ['label' => $english],
            );

            $node->translations()->firstOrCreate(
                ['locale' => 'ur'],
                ['label' => $romanUrdu],
            );
        }
    }
}
