<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Enums\Profile\ReligionNodeType;
use App\Models\ReligionTaxonomyNode;
use App\Models\User;
use App\Models\UserReligionProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ShowReligionProfileEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_authentication_is_required(): void
    {
        $this->getJson('/api/v1/onboarding/religion-profile')
            ->assertUnauthorized();
    }

    public function test_null_profile_is_returned_before_selection(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);

        $this->withHeader('Accept-Language', 'ur-PK')
            ->getJson('/api/v1/onboarding/religion-profile')
            ->assertOk()
            ->assertJsonPath('data.religion_profile', null);
    }

    public function test_saved_profile_returns_the_complete_selected_path(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);

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
        $religion->translations()->createMany([
            ['locale' => 'en', 'label' => 'Islam'],
            ['locale' => 'ur', 'label' => 'Islam'],
        ]);
        $sect->translations()->createMany([
            ['locale' => 'en', 'label' => 'Sunni'],
            ['locale' => 'ur', 'label' => 'Sunni'],
        ]);

        UserReligionProfile::query()->create([
            'user_id' => $user->id,
            'selected_node_id' => $sect->id,
            'country_code' => 'PK',
        ]);

        $this->withHeader('Accept-Language', 'ur')
            ->getJson('/api/v1/onboarding/religion-profile')
            ->assertOk()
            ->assertJsonPath(
                'data.religion_profile.selected_node_id',
                $sect->public_id,
            )
            ->assertJsonPath('data.religion_profile.country', 'PK')
            ->assertJsonPath(
                'data.religion_profile.path.0.id',
                $religion->public_id,
            )
            ->assertJsonPath(
                'data.religion_profile.path.1.id',
                $sect->public_id,
            )
            ->assertJsonPath(
                'data.religion_profile.path.0.label',
                'Islam',
            )
            ->assertJsonPath(
                'data.religion_profile.path.0.label_locale',
                'ur',
            )
            ->assertJsonPath(
                'data.religion_profile.path.1.label',
                'Sunni',
            )
            ->assertJsonCount(2, 'data.religion_profile.path');
    }
}
