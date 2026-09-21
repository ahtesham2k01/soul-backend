<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Enums\Profile\RelationshipIntention;
use App\Enums\Profile\ReligionNodeType;
use App\Models\ProfilePhoto;
use App\Models\ReligionTaxonomyNode;
use App\Models\SpokenLanguage;
use App\Models\User;
use App\Models\UserProfile;
use App\Models\UserProfileIntention;
use App\Models\UserReligionProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileDraftEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_returns_401_when_profile_draft_is_unauthenticated(): void
    {
        $this->getJson('/api/v1/onboarding/profile')
            ->assertUnauthorized();

        $this->putJson('/api/v1/onboarding/profile', [])
            ->assertUnauthorized();
    }

    public function test_returns_null_before_profile_draft_is_started(): void
    {
        Sanctum::actingAs(User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]));

        $this->getJson('/api/v1/onboarding/profile')
            ->assertOk()
            ->assertJsonPath('data.profile', null);
    }

    public function test_valid_partial_payload_creates_draft_and_returns_200(): void
    {
        $this->travelTo('2026-09-01 12:00:00');
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);
        SpokenLanguage::factory()->create([
            'code' => 'ur',
            'name' => 'Urdu',
            'native_name' => 'اردو',
        ]);

        $response = $this->putJson('/api/v1/onboarding/profile', [
            'first_name' => 'Ayesha',
            'date_of_birth' => '1998-04-12',
            'gender' => 'woman',
            'country_code' => 'pk',
            'intentions' => ['marriage', 'serious_relationship'],
            'spoken_language_codes' => ['ur'],
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.profile.first_name', 'Ayesha')
            ->assertJsonPath('data.profile.country_code', 'PK')
            ->assertJsonPath('data.profile.intentions.0', 'marriage')
            ->assertJsonPath('data.profile.spoken_languages.0.code', 'ur');
        $this->assertDatabaseHas('user_profiles', [
            'user_id' => $user->id,
            'first_name' => 'Ayesha',
            'country_code' => 'PK',
        ]);
        $this->assertDatabaseCount('user_profile_intentions', 2);
        $this->assertDatabaseCount('spoken_language_user_profile', 1);
    }

    public function test_repeated_save_updates_one_draft_and_syncs_selections(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        Sanctum::actingAs($user);
        SpokenLanguage::factory()->create([
            'code' => 'en',
            'name' => 'English',
            'native_name' => 'English',
        ]);
        SpokenLanguage::factory()->create([
            'code' => 'ur',
            'name' => 'Urdu',
            'native_name' => 'اردو',
        ]);

        $this->putJson('/api/v1/onboarding/profile', [
            'first_name' => 'Old name',
            'intentions' => ['casual_dating'],
            'spoken_language_codes' => ['en'],
        ])->assertOk();

        $this->putJson('/api/v1/onboarding/profile', [
            'first_name' => 'New name',
            'intentions' => ['marriage'],
            'spoken_language_codes' => ['ur'],
        ])
            ->assertOk()
            ->assertJsonPath('data.profile.first_name', 'New name')
            ->assertJsonPath('data.profile.intentions.0', 'marriage')
            ->assertJsonPath('data.profile.spoken_languages.0.code', 'ur');

        $this->assertDatabaseCount('user_profiles', 1);
        $this->assertDatabaseCount('user_profile_intentions', 1);
        $this->assertDatabaseCount('spoken_language_user_profile', 1);
    }

    public function test_live_profile_cannot_be_saved_in_an_incomplete_state(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);
        $profile = UserProfile::factory()->for($user)->create([
            'profile_status' => 'live',
            'city_name' => 'Karachi',
        ]);
        $language = SpokenLanguage::factory()->create();
        $profile->spokenLanguages()->attach($language);
        UserProfileIntention::factory()->for($profile)->create([
            'intention' => RelationshipIntention::Marriage,
        ]);

        $religion = ReligionTaxonomyNode::query()->create([
            'type' => ReligionNodeType::Religion,
            'slug' => 'islam',
            'path' => 'islam',
            'is_active' => true,
        ]);
        UserReligionProfile::query()->create([
            'user_id' => $user->id,
            'selected_node_id' => $religion->id,
            'country_code' => 'PK',
        ]);
        ProfilePhoto::factory()->for($profile)->create([
            'position' => 1,
            'visibility' => ProfilePhotoVisibility::Public,
            'moderation_status' => ProfilePhotoModerationStatus::Approved,
            'face_detected' => true,
        ]);

        Sanctum::actingAs($user);

        $this->putJson('/api/v1/onboarding/profile', [
            'city_name' => null,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');

        $this->assertDatabaseHas('user_profiles', [
            'id' => $profile->id,
            'profile_status' => 'live',
            'city_name' => 'Karachi',
        ]);
    }

    public function test_returns_422_for_underage_or_unknown_language(): void
    {
        $this->travelTo('2026-09-01 12:00:00');
        Sanctum::actingAs(User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]));

        $this->putJson('/api/v1/onboarding/profile', [
            'date_of_birth' => '2009-09-01',
            'spoken_language_codes' => ['unknown'],
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure([
                'error' => [
                    'details' => [
                        'fields' => [
                            'date_of_birth',
                            'spoken_language_codes.0',
                        ],
                    ],
                ],
            ]);

        $this->assertDatabaseCount('user_profiles', 0);
    }
}
