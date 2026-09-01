<?php

namespace Tests\Feature\Api\V1\Discovery;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Models\ProfilePhoto;
use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DiscoveryEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_discovery_endpoints_require_authentication(): void
    {
        $this->getJson('/api/v1/discovery/preferences')->assertUnauthorized();
        $this->putJson('/api/v1/discovery/preferences')->assertUnauthorized();
        $this->getJson('/api/v1/discovery/candidates')->assertUnauthorized();
    }

    public function test_preferences_are_validated_saved_and_resumed_without_internal_ids(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/discovery/preferences', [
            'preferred_gender' => 'woman',
            'minimum_age' => 24,
            'maximum_age' => 35,
            'same_country_only' => true,
        ])->assertOk()
            ->assertJsonPath('data.preferences.minimum_age', 24)
            ->assertJsonMissingPath('data.preferences.user_id');

        $this->getJson('/api/v1/discovery/preferences')
            ->assertOk()->assertJsonPath('data.preferences.preferred_gender', 'woman');

        $this->putJson('/api/v1/discovery/preferences', [
            'preferred_gender' => 'woman',
            'minimum_age' => 40,
            'maximum_age' => 30,
            'same_country_only' => true,
        ])->assertUnprocessable();
        $this->assertDatabaseCount('discovery_preferences', 1);
    }

    public function test_discovery_requires_live_viewer_and_preferences(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create(['profile_status' => 'draft']);
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/discovery/candidates')
            ->assertConflict()->assertJsonPath('error.code', 'DISCOVERY_NOT_READY');
    }

    public function test_candidates_apply_eligibility_filters_and_hide_private_photos(): void
    {
        $viewer = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($viewer)->create([
            'profile_status' => 'live', 'gender' => 'man', 'country_code' => 'PK',
        ]);
        $viewer->discoveryPreference()->create([
            'preferred_gender' => 'woman', 'minimum_age' => 25,
            'maximum_age' => 35, 'same_country_only' => true,
        ]);
        $candidate = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $candidateProfile = UserProfile::factory()->for($candidate)->create([
            'profile_status' => 'live', 'gender' => 'woman',
            'country_code' => 'PK', 'date_of_birth' => now()->subYears(30),
        ]);
        $visible = ProfilePhoto::factory()->for($candidateProfile)->create([
            'visibility' => ProfilePhotoVisibility::Public,
            'moderation_status' => ProfilePhotoModerationStatus::Approved,
        ]);
        ProfilePhoto::factory()->for($candidateProfile)->create([
            'position' => 2, 'visibility' => ProfilePhotoVisibility::Private,
            'moderation_status' => ProfilePhotoModerationStatus::Approved,
        ]);
        UserProfile::factory()->create([
            'profile_status' => 'live', 'gender' => 'woman',
            'country_code' => 'US', 'date_of_birth' => now()->subYears(30),
        ]);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')
            ->assertOk()
            ->assertJsonCount(1, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $candidateProfile->public_id)
            ->assertJsonPath('data.candidates.0.photos.0.id', $visible->public_id)
            ->assertJsonCount(1, 'data.candidates.0.photos')
            ->assertJsonMissingPath('data.candidates.0.date_of_birth')
            ->assertJsonMissingPath('data.candidates.0.user_id');
    }

    public function test_candidates_exclude_profiles_already_decided_by_viewer(): void
    {
        $viewer = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($viewer)->create([
            'profile_status' => 'live',
            'gender' => 'man',
            'country_code' => 'PK',
        ]);
        $viewer->discoveryPreference()->create([
            'preferred_gender' => 'woman',
            'minimum_age' => 18,
            'maximum_age' => 60,
            'same_country_only' => false,
        ]);
        $candidate = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($candidate)->create([
            'profile_status' => 'live',
            'gender' => 'woman',
            'date_of_birth' => now()->subYears(30),
        ]);
        ProfileDecision::query()->create([
            'actor_user_id' => $viewer->id,
            'target_user_id' => $candidate->id,
            'decision' => 'pass',
        ]);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')
            ->assertOk()
            ->assertJsonCount(0, 'data.candidates');
    }
}
