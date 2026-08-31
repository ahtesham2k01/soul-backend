<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Enums\Profile\ReligionNodeType;
use App\Models\ReligionTaxonomyNode;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReligionOptionsEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_root_options_use_requested_localized_labels(): void
    {
        $islam = $this->node(
            type: ReligionNodeType::Religion,
            slug: 'islam',
            path: 'islam',
        );

        $islam->translations()->createMany([
            ['locale' => 'en', 'label' => 'Islam'],
            ['locale' => 'ur', 'label' => 'اسلام'],
        ]);

        $response = $this->getJson(
            '/api/v1/onboarding/religion-options?locale=ur-PK&country=pk',
        );

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.parent', null)
            ->assertJsonPath('data.options.0.id', $islam->public_id)
            ->assertJsonPath('data.options.0.type', 'religion')
            ->assertJsonPath('data.options.0.label', 'اسلام')
            ->assertJsonPath('data.options.0.label_locale', 'ur')
            ->assertJsonPath('meta.locale', 'ur')
            ->assertJsonPath('meta.country', 'PK')
            ->assertJsonStructure([
                'meta' => ['request_id'],
            ]);
    }

    public function test_children_are_loaded_one_level_at_a_time(): void
    {
        $islam = $this->node(
            type: ReligionNodeType::Religion,
            slug: 'islam',
            path: 'islam',
        );

        $sunni = $this->node(
            type: ReligionNodeType::Sect,
            slug: 'sunni',
            path: 'islam/sunni',
            parent: $islam,
        );

        $this->node(
            type: ReligionNodeType::School,
            slug: 'hanafi',
            path: 'islam/sunni/hanafi',
            parent: $sunni,
        );

        $response = $this->getJson(
            '/api/v1/onboarding/religion-options?parent_id='
            .$islam->public_id.'&locale=en',
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.parent.id', $islam->public_id)
            ->assertJsonPath('data.options.0.id', $sunni->public_id)
            ->assertJsonPath('data.options.0.has_children', true)
            ->assertJsonCount(1, 'data.options');
    }

    public function test_country_restricted_options_are_filtered(): void
    {
        $islam = $this->node(
            type: ReligionNodeType::Religion,
            slug: 'islam',
            path: 'islam',
        );

        $global = $this->node(
            type: ReligionNodeType::Community,
            slug: 'global-community',
            path: 'islam/global-community',
            parent: $islam,
        );

        $pakistanOnly = $this->node(
            type: ReligionNodeType::Caste,
            slug: 'pakistan-caste',
            path: 'islam/pakistan-caste',
            parent: $islam,
        );

        $pakistanOnly->countries()->create([
            'country_code' => 'PK',
        ]);

        $usResponse = $this->getJson(
            '/api/v1/onboarding/religion-options?parent_id='
            .$islam->public_id.'&country=US',
        );

        $pkResponse = $this->getJson(
            '/api/v1/onboarding/religion-options?parent_id='
            .$islam->public_id.'&country=PK',
        );

        $usResponse
            ->assertOk()
            ->assertJsonCount(1, 'data.options')
            ->assertJsonPath('data.options.0.id', $global->public_id);

        $pkResponse
            ->assertOk()
            ->assertJsonCount(2, 'data.options');
    }

    public function test_inactive_options_are_not_returned(): void
    {
        $this->node(
            type: ReligionNodeType::Religion,
            slug: 'islam',
            path: 'islam',
        );

        $this->node(
            type: ReligionNodeType::Religion,
            slug: 'hidden-religion',
            path: 'hidden-religion',
            active: false,
        );

        $this->getJson('/api/v1/onboarding/religion-options')
            ->assertOk()
            ->assertJsonCount(1, 'data.options')
            ->assertJsonPath('data.options.0.slug', 'islam');
    }

    public function test_invalid_parent_and_country_are_rejected(): void
    {
        $this->getJson(
            '/api/v1/onboarding/religion-options'
            .'?parent_id=not-a-ulid&country=Pakistan',
        )
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure([
                'error' => [
                    'details' => [
                        'fields' => [
                            'parent_id',
                            'country',
                        ],
                    ],
                ],
            ]);
    }

    private function node(
        ReligionNodeType $type,
        string $slug,
        string $path,
        ?ReligionTaxonomyNode $parent = null,
        bool $active = true,
    ): ReligionTaxonomyNode {
        return ReligionTaxonomyNode::query()->create([
            'parent_id' => $parent?->id,
            'type' => $type,
            'slug' => $slug,
            'path' => $path,
            'is_active' => $active,
        ]);
    }
}
