<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Enums\Profile\ReligionNodeType;
use App\Models\ReligionTaxonomyNode;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StoreReligionProfileEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_authentication_is_required(): void
    {
        $this->putJson('/api/v1/onboarding/religion-profile', [])
            ->assertUnauthorized();
    }

    public function test_leaf_selection_is_saved_idempotently(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);

        [$religion, $sect] = $this->createTree();

        $payload = [
            'selected_node_id' => $sect->public_id,
            'country' => 'pk',
        ];

        $this->putJson(
            '/api/v1/onboarding/religion-profile',
            $payload,
        )
            ->assertOk()
            ->assertJsonPath(
                'data.religion_profile.selected_node_id',
                $sect->public_id,
            )
            ->assertJsonPath(
                'data.religion_profile.country',
                'PK',
            )
            ->assertJsonCount(
                2,
                'data.religion_profile.path',
            );

        $this->putJson(
            '/api/v1/onboarding/religion-profile',
            $payload,
        )->assertOk();

        $this->assertDatabaseCount(
            'user_religion_profiles',
            1,
        );
        $this->assertDatabaseHas(
            'user_religion_profiles',
            [
                'user_id' => $user->id,
                'selected_node_id' => $sect->id,
                'country_code' => 'PK',
            ],
        );
        $this->assertSame(
            $religion->public_id,
            $user->religionProfile
                ->selectedNode
                ->parent
                ->public_id,
        );
    }

    public function test_non_leaf_selection_is_rejected(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);

        [$religion] = $this->createTree();

        $this->putJson(
            '/api/v1/onboarding/religion-profile',
            ['selected_node_id' => $religion->public_id],
        )
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'RELIGION_SELECTION_INCOMPLETE',
            );

        $this->assertDatabaseCount(
            'user_religion_profiles',
            0,
        );
    }

    public function test_country_restricted_selection_is_enforced(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);

        [, $sect] = $this->createTree();
        $sect->countries()->create([
            'country_code' => 'PK',
        ]);

        $this->putJson(
            '/api/v1/onboarding/religion-profile',
            [
                'selected_node_id' => $sect->public_id,
                'country' => 'US',
            ],
        )
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'RELIGION_OPTION_UNAVAILABLE',
            );
    }

    /** @return array{ReligionTaxonomyNode, ReligionTaxonomyNode} */
    private function createTree(): array
    {
        $religion = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
        ]);

        $sect = $religion->children()->create([
            'type' => ReligionNodeType::Sect,
            'slug' => 'sunni',
            'path' => 'islam/sunni',
        ]);

        return [$religion, $sect];
    }
}
