<?php

namespace Tests\Feature\Models;

use App\Enums\Profile\ReligionNodeType;
use App\Models\ReligionTaxonomyNode;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReligionTaxonomyNodeModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_dynamic_religion_tree_can_store_different_level_names(): void
    {
        $islam = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
        ]);

        $sunni = $islam->children()->create([
            'type' => ReligionNodeType::Sect,
            'slug' => 'sunni',
            'path' => 'islam/sunni',
        ]);

        $hanafi = $sunni->children()->create([
            'type' => ReligionNodeType::School,
            'slug' => 'hanafi',
            'path' => 'islam/sunni/hanafi',
        ]);

        $this->assertSame(
            ReligionNodeType::Religion,
            $islam->type,
        );

        $this->assertSame(
            ReligionNodeType::School,
            $hanafi->type,
        );

        $this->assertTrue(
            $hanafi->parent->is($sunni),
        );
    }

    public function test_node_has_unique_stable_path(): void
    {
        ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
        ]);

        $this->expectException(QueryException::class);

        ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'duplicate-islam',
            'path' => 'islam',
        ]);
    }

    public function test_node_supports_unique_multilingual_labels(): void
    {
        $islam = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
        ]);

        $islam->translations()->createMany([
            [
                'locale' => 'en',
                'label' => 'Islam',
            ],
            [
                'locale' => 'ur',
                'label' => 'اسلام',
            ],
        ]);

        $this->assertSame(
            ['Islam', 'اسلام'],
            $islam->translations()->orderBy('id')->pluck('label')->all(),
        );

        $this->expectException(QueryException::class);

        $islam->translations()->create([
            'locale' => 'en',
            'label' => 'Duplicate English label',
        ]);
    }

    public function test_country_restricted_nodes_are_only_available_in_configured_countries(): void
    {
        $global = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
        ]);

        $pakistanOnly = ReligionTaxonomyNode::query()->create([
            'parent_id' => $global->id,
            'type' => ReligionNodeType::Community,
            'slug' => 'pakistan-community',
            'path' => 'islam/pakistan-community',
        ]);

        $pakistanOnly->countries()->create([
            'country_code' => 'pk',
        ]);

        $pakistanIds = ReligionTaxonomyNode::query()
            ->availableInCountry('PK')
            ->pluck('id');

        $usIds = ReligionTaxonomyNode::query()
            ->availableInCountry('US')
            ->pluck('id');

        $this->assertTrue($pakistanIds->contains($global->id));
        $this->assertTrue($pakistanIds->contains($pakistanOnly->id));
        $this->assertTrue($usIds->contains($global->id));
        $this->assertFalse($usIds->contains($pakistanOnly->id));
    }

    public function test_deleting_parent_cascades_to_children_and_metadata(): void
    {
        $islam = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
        ]);

        $sunni = $islam->children()->create([
            'type' => ReligionNodeType::Sect,
            'slug' => 'sunni',
            'path' => 'islam/sunni',
        ]);

        $sunni->translations()->create([
            'locale' => 'en',
            'label' => 'Sunni',
        ]);

        $sunni->countries()->create([
            'country_code' => 'PK',
        ]);

        $islam->delete();

        $this->assertDatabaseCount('religion_taxonomy_nodes', 0);
        $this->assertDatabaseCount('religion_taxonomy_translations', 0);
        $this->assertDatabaseCount('religion_taxonomy_countries', 0);
    }

    public function test_internal_ids_are_hidden_from_json(): void
    {
        $node = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Belief,
            'slug' => 'agnostic',
            'path' => 'agnostic',
        ]);

        $serialized = $node->toArray();

        $this->assertArrayNotHasKey('id', $serialized);
        $this->assertArrayNotHasKey('parent_id', $serialized);
        $this->assertArrayHasKey('public_id', $serialized);
        $this->assertArrayHasKey('type', $serialized);
    }
}
