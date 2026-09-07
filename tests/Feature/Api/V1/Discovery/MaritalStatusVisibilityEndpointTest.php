<?php

namespace Tests\Feature\Api\V1\Discovery;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Models\ProfilePhoto;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MaritalStatusVisibilityEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_married_status_is_prominent_on_discovery_card_and_full_profile(): void
    {
        [$viewer, $candidate, $profile] = $this->viewerAndCandidate();
        $profile->update(['marital_status' => 'married', 'bio' => 'A short bio']);
        $profile->intentions()->createMany([
            ['intention' => 'marriage'],
            ['intention' => 'serious_relationship'],
            ['intention' => 'casual_dating'],
        ]);
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/discovery/candidates')->assertOk()
            ->assertJsonPath('data.candidates.0.id', $profile->public_id)
            ->assertJsonPath('data.candidates.0.marital_status', 'married');

        $this->getJson("/api/v1/profiles/{$profile->public_id}")->assertOk()
            ->assertJsonPath('data.profile.marital_status', 'married')
            ->assertJsonCount(3, 'data.profile.intentions')
            ->assertJsonMissingPath('data.profile.date_of_birth')
            ->assertJsonMissingPath('data.profile.user_id');
    }

    public function test_marital_status_cannot_be_hidden_or_replaced_by_partner_questions(): void
    {
        [$viewer, , $profile] = $this->viewerAndCandidate();
        Sanctum::actingAs($viewer);

        $this->putJson('/api/v1/onboarding/profile', [
            'prefer_not_to_say_fields' => ['marital_status'],
        ])->assertUnprocessable();

        $this->putJson('/api/v1/onboarding/profile', [
            'partner_consent' => true,
            'polygamy_preference' => 'allowed',
        ])->assertOk()->assertJsonMissingPath('data.profile.partner_consent')
            ->assertJsonMissingPath('data.profile.polygamy_preference');

        $this->assertDatabaseMissing('user_profile_withheld_fields', [
            'user_profile_id' => $profile->id, 'field' => 'marital_status',
        ]);
    }

    public function test_optional_withheld_field_is_hidden_but_marital_status_remains_visible(): void
    {
        [$viewer, , $profile] = $this->viewerAndCandidate();
        $profile->update(['marital_status' => 'divorced', 'employer' => 'Private Company']);
        $profile->withheldFields()->create(['field' => 'employer']);
        Sanctum::actingAs($viewer);

        $this->getJson("/api/v1/profiles/{$profile->public_id}")->assertOk()
            ->assertJsonPath('data.profile.marital_status', 'divorced')
            ->assertJsonPath('data.profile.employer', null);
    }

    public function test_paused_profile_stays_available_to_an_existing_match_but_not_other_users(): void
    {
        [$viewer, , $profile] = $this->viewerAndCandidate();
        $profile->user->privacySetting()->create(['profile_paused' => true]);
        Sanctum::actingAs($viewer);
        $this->getJson("/api/v1/profiles/{$profile->public_id}")->assertNotFound();

        $ids = [$viewer->id, $profile->user_id];
        sort($ids);
        UserMatch::query()->create([
            'first_user_id' => $ids[0], 'second_user_id' => $ids[1],
            'status' => 'active', 'matched_at' => now(),
        ]);

        $this->getJson("/api/v1/profiles/{$profile->public_id}")->assertOk()
            ->assertJsonPath('data.profile.marital_status', 'never_married');
    }

    public function test_blocked_or_suspended_profile_is_non_enumerating(): void
    {
        [$viewer, $candidate, $profile] = $this->viewerAndCandidate();
        $candidate->forceFill(['status' => User::STATUS_SUSPENDED])->save();
        Sanctum::actingAs($viewer);
        $this->getJson("/api/v1/profiles/{$profile->public_id}")
            ->assertNotFound()->assertJsonPath('error.code', 'PROFILE_UNAVAILABLE');
    }

    private function viewerAndCandidate(): array
    {
        $viewer = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($viewer)->create([
            'profile_status' => 'live', 'gender' => 'man', 'country_code' => 'PK',
            'marital_status' => 'never_married',
        ]);
        $viewer->discoveryPreference()->create([
            'preferred_gender' => 'woman', 'minimum_age' => 18, 'maximum_age' => 60,
            'same_country_only' => false, 'religion_mode' => 'all_religions',
        ]);
        $candidate = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($candidate)->create([
            'profile_status' => 'live', 'gender' => 'woman', 'country_code' => 'PK',
            'marital_status' => 'never_married', 'date_of_birth' => now()->subYears(30),
        ]);
        ProfilePhoto::factory()->for($profile)->create([
            'visibility' => ProfilePhotoVisibility::Public,
            'moderation_status' => ProfilePhotoModerationStatus::Approved,
        ]);

        return [$viewer, $candidate, $profile];
    }
}
