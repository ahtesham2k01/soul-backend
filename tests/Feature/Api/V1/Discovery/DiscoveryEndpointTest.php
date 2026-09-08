<?php

namespace Tests\Feature\Api\V1\Discovery;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Models\ProfileDecision;
use App\Models\ProfilePhoto;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
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
            ->assertJsonPath('data.preferences.religion_mode', 'my_religion')
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
            'religion_mode' => 'all_religions',
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
            'religion_mode' => 'all_religions',
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

    public function test_passed_profiles_resurface_after_thirty_days_but_liked_profiles_do_not(): void
    {
        Carbon::setTestNow('2026-09-02 12:00:00');
        $viewer = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($viewer)->create(['profile_status' => 'live', 'gender' => 'man']);
        $viewer->discoveryPreference()->create(['preferred_gender' => 'woman', 'minimum_age' => 18, 'maximum_age' => 60, 'same_country_only' => false, 'religion_mode' => 'all_religions']);
        $recentPass = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $expiredPass = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $liked = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        foreach ([$recentPass, $expiredPass, $liked] as $candidate) {
            UserProfile::factory()->for($candidate)->create(['profile_status' => 'live', 'gender' => 'woman', 'date_of_birth' => now()->subYears(30)]);
        }
        ProfileDecision::query()->create(['actor_user_id' => $viewer->id, 'target_user_id' => $recentPass->id, 'decision' => 'pass'])->forceFill(['updated_at' => now()->subDays(29)])->save();
        ProfileDecision::query()->create(['actor_user_id' => $viewer->id, 'target_user_id' => $expiredPass->id, 'decision' => 'pass'])->forceFill(['updated_at' => now()->subDays(31)])->save();
        ProfileDecision::query()->create(['actor_user_id' => $viewer->id, 'target_user_id' => $liked->id, 'decision' => 'like'])->forceFill(['updated_at' => now()->subDays(31)])->save();
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')->assertOk()
            ->assertJsonCount(1, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $expiredPass->profile->public_id)
            ->assertJsonPath('data.candidates.0.age', 30);
    }
}
