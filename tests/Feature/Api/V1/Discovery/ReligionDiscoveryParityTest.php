<?php

namespace Tests\Feature\Api\V1\Discovery;

use App\Models\ReligionTaxonomyNode;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReligionDiscoveryParityTest extends TestCase
{
    use RefreshDatabase;

    public function test_my_religion_is_default_and_persists_when_mode_changes(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/discovery/preferences', $this->preferences())
            ->assertOk()
            ->assertJsonPath('data.preferences.religion_mode', 'my_religion');

        $this->putJson('/api/v1/discovery/preferences', $this->preferences([
            'religion_mode' => 'all_religions',
        ]))->assertOk()->assertJsonPath('data.preferences.religion_mode', 'all_religions');

        $this->getJson('/api/v1/discovery/preferences')
            ->assertOk()
            ->assertJsonPath('data.preferences.religion_mode', 'all_religions');

        $this->putJson('/api/v1/discovery/preferences', $this->preferences([
            'religion_mode' => 'same_sect',
        ]))->assertUnprocessable();
    }

    public function test_my_religion_matches_root_only_and_ignores_deeper_hierarchy(): void
    {
        [$islam, $sunni, $shia] = $this->religionTree('islam');
        [$christianity, $catholic] = $this->religionTree('christianity');

        $viewer = $this->liveUser('man');
        $this->selectReligion($viewer, $sunni, $islam);
        $viewer->discoveryPreference()->create($this->preferences(['religion_mode' => 'my_religion']));

        $sameRoot = $this->liveUser('woman');
        $this->selectReligion($sameRoot, $shia, $islam);
        $otherRoot = $this->liveUser('woman');
        $this->selectReligion($otherRoot, $catholic, $christianity);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')
            ->assertOk()
            ->assertJsonCount(1, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $sameRoot->profile->public_id)
            ->assertJsonPath('data.candidates.0.religion.id', $islam->public_id)
            ->assertJsonPath('data.candidates.0.religion.slug', 'islam');

        $viewer->discoveryPreference->update(['religion_mode' => 'all_religions']);

        $this->getJson('/api/v1/discovery/candidates')
            ->assertOk()
            ->assertJsonCount(2, 'data.candidates');
    }

    public function test_my_religion_requires_a_saved_root_but_all_religions_does_not(): void
    {
        $viewer = $this->liveUser('man');
        $viewer->discoveryPreference()->create($this->preferences(['religion_mode' => 'my_religion']));
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')
            ->assertConflict()
            ->assertJsonPath('error.code', 'DISCOVERY_RELIGION_REQUIRED');

        $viewer->discoveryPreference->update(['religion_mode' => 'all_religions']);
        $this->getJson('/api/v1/discovery/candidates')->assertOk();
    }

    public function test_religion_save_records_root_and_rejects_unavailable_ancestor(): void
    {
        [$root, $leaf] = $this->religionTree('country-restricted');
        $root->countries()->create(['country_code' => 'US']);
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/onboarding/religion-profile', [
            'selected_node_id' => $leaf->public_id,
            'country' => 'PK',
        ])->assertUnprocessable()->assertJsonPath('error.code', 'RELIGION_OPTION_UNAVAILABLE');

        $this->putJson('/api/v1/onboarding/religion-profile', [
            'selected_node_id' => $leaf->public_id,
            'country' => 'US',
        ])->assertOk()
            ->assertJsonPath('data.religion_profile.root_node_id', $root->public_id);

        $this->assertDatabaseHas('user_religion_profiles', [
            'user_id' => $user->id,
            'selected_node_id' => $leaf->id,
            'root_node_id' => $root->id,
        ]);
    }

    /** @return array{ReligionTaxonomyNode, ReligionTaxonomyNode, ReligionTaxonomyNode} */
    private function religionTree(string $slug): array
    {
        $root = ReligionTaxonomyNode::query()->create([
            'type' => 'religion', 'slug' => $slug, 'path' => $slug, 'is_active' => true,
        ]);
        $first = $root->children()->create([
            'type' => 'sect', 'slug' => $slug.'-first', 'path' => $slug.'/'.$slug.'-first', 'is_active' => true,
        ]);
        $second = $root->children()->create([
            'type' => 'sect', 'slug' => $slug.'-second', 'path' => $slug.'/'.$slug.'-second', 'is_active' => true,
        ]);

        return [$root, $first, $second];
    }

    private function liveUser(string $gender): User
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create([
            'profile_status' => 'live',
            'gender' => $gender,
            'country_code' => 'PK',
            'date_of_birth' => now()->subYears(30),
        ]);

        return $user;
    }

    private function selectReligion(User $user, ReligionTaxonomyNode $selected, ReligionTaxonomyNode $root): void
    {
        $user->religionProfile()->create([
            'selected_node_id' => $selected->id,
            'root_node_id' => $root->id,
            'country_code' => 'PK',
        ]);
    }

    private function preferences(array $overrides = []): array
    {
        return array_merge([
            'preferred_gender' => 'woman',
            'minimum_age' => 18,
            'maximum_age' => 60,
            'same_country_only' => false,
        ], $overrides);
    }
}
