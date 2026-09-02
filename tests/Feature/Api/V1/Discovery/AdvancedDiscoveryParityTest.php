<?php

namespace Tests\Feature\Api\V1\Discovery;

use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdvancedDiscoveryParityTest extends TestCase
{
    use RefreshDatabase;

    public function test_preferences_persist_selected_locations_intentions_and_radius(): void
    {
        $viewer = $this->liveUser('man');
        Sanctum::actingAs($viewer);

        $this->putJson('/api/v1/discovery/preferences', $this->preferences([
            'location_mode' => 'selected',
            'radius_km' => 50,
            'selected_locations' => [
                ['country_code' => 'pk', 'city_name' => 'Karachi'],
                ['country_code' => 'AE', 'city_name' => null],
            ],
            'intentions' => ['marriage', 'serious_relationship'],
        ]))->assertOk()
            ->assertJsonPath('data.preferences.location_mode', 'selected')
            ->assertJsonPath('data.preferences.radius_km', 50)
            ->assertJsonFragment(['country_code' => 'PK', 'city_name' => 'Karachi'])
            ->assertJsonCount(2, 'data.preferences.intentions');

        $this->assertDatabaseCount('discovery_preference_locations', 2);
        $this->assertDatabaseCount('discovery_preference_intentions', 2);

        $this->putJson('/api/v1/discovery/preferences', $this->preferences([
            'location_mode' => 'selected', 'selected_locations' => [],
        ]))->assertUnprocessable();
    }

    public function test_radius_filters_candidates_and_returns_only_a_safe_distance_band(): void
    {
        $viewer = $this->liveUser('man', ['latitude' => 24.860700, 'longitude' => 67.001100]);
        $viewer->discoveryPreference()->create($this->preferences(['radius_km' => 10]));
        $near = $this->liveUser('woman', ['latitude' => 24.900000, 'longitude' => 67.020000]);
        $this->liveUser('woman', ['latitude' => 25.500000, 'longitude' => 67.500000]);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')->assertOk()
            ->assertJsonCount(1, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $near->profile->public_id)
            ->assertJsonPath('data.candidates.0.distance_band', 'distance.about_5_km')
            ->assertJsonMissingPath('data.candidates.0.latitude')
            ->assertJsonMissingPath('data.candidates.0.longitude');
    }

    public function test_selected_location_and_intention_filters_are_both_applied(): void
    {
        $viewer = $this->liveUser('man');
        $preference = $viewer->discoveryPreference()->create($this->preferences(['location_mode' => 'selected']));
        $preference->locations()->create(['country_code' => 'PK', 'city_name' => 'Karachi']);
        $preference->intentions()->create(['intention' => 'marriage']);
        $match = $this->liveUser('woman', ['city_name' => 'Karachi']);
        $match->profile->intentions()->create(['intention' => 'marriage']);
        $wrongCity = $this->liveUser('woman', ['city_name' => 'Lahore']);
        $wrongCity->profile->intentions()->create(['intention' => 'marriage']);
        $wrongIntention = $this->liveUser('woman', ['city_name' => 'Karachi']);
        $wrongIntention->profile->intentions()->create(['intention' => 'casual_dating']);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')->assertOk()
            ->assertJsonCount(1, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $match->profile->public_id);
    }

    public function test_inactive_profiles_rank_lower_after_thirty_days_and_hide_after_ninety(): void
    {
        $viewer = $this->liveUser('man');
        $viewer->discoveryPreference()->create($this->preferences());
        $recent = $this->liveUser('woman', ['last_active_at' => now()->subDay()]);
        $older = $this->liveUser('woman', ['last_active_at' => now()->subDays(45)]);
        $this->liveUser('woman', ['last_active_at' => now()->subDays(91)]);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')->assertOk()
            ->assertJsonCount(2, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $recent->profile->public_id)
            ->assertJsonPath('data.candidates.1.id', $older->profile->public_id);
    }

    public function test_pause_incognito_and_contact_hiding_enforce_privacy_without_exposing_hashes(): void
    {
        $viewer = $this->liveUser('man');
        $viewer->discoveryPreference()->create($this->preferences());
        $viewer->privacySetting()->create(['hide_contacts' => true]);
        $contact = $this->liveUser('woman', [], '+92 300 1112233');
        $paused = $this->liveUser('woman');
        $paused->privacySetting()->create(['profile_paused' => true]);
        $incognito = $this->liveUser('woman');
        $incognito->privacySetting()->create(['incognito' => true]);
        Sanctum::actingAs($viewer);

        $this->putJson('/api/v1/privacy/contacts', ['phone_numbers' => ['+92 300 1112233']])
            ->assertOk()->assertJsonPath('data.hidden_contacts_count', 1)
            ->assertJsonMissingPath('data.phone_hash');

        $this->getJson('/api/v1/discovery/candidates')->assertOk()->assertJsonCount(0, 'data.candidates');
        $this->postJson('/api/v1/profiles/'.$incognito->profile->public_id.'/decision', ['decision' => 'like'])
            ->assertNotFound()->assertJsonPath('error.code', 'PROFILE_UNAVAILABLE');

        ProfileDecision::query()->create(['actor_user_id' => $incognito->id, 'target_user_id' => $viewer->id, 'decision' => 'like']);
        $this->getJson('/api/v1/discovery/candidates')->assertOk()
            ->assertJsonCount(1, 'data.candidates')
            ->assertJsonPath('data.candidates.0.id', $incognito->profile->public_id);

        $this->assertDatabaseHas('hidden_contact_hashes', ['user_id' => $viewer->id]);
        $this->assertDatabaseMissing('hidden_contact_hashes', ['phone_hash' => '+92 300 1112233']);
        $this->assertNotNull($contact->phone_lookup_hash);
    }

    private function liveUser(string $gender, array $profile = [], ?string $phone = null): User
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE, 'phone' => $phone]);
        UserProfile::factory()->for($user)->create(array_merge([
            'profile_status' => 'live', 'gender' => $gender, 'country_code' => 'PK',
            'city_name' => 'Karachi', 'date_of_birth' => now()->subYears(30),
        ], $profile));

        return $user->fresh();
    }

    private function preferences(array $overrides = []): array
    {
        return array_merge([
            'preferred_gender' => 'woman', 'minimum_age' => 18, 'maximum_age' => 60,
            'same_country_only' => false, 'religion_mode' => 'all_religions', 'location_mode' => 'anywhere',
        ], $overrides);
    }
}
