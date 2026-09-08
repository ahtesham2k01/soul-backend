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

class OnboardingReadinessEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_returns_401_when_unauthenticated(): void
    {
        $this->getJson('/api/v1/onboarding/readiness')
            ->assertUnauthorized();
    }

    public function test_reports_missing_requirements_before_profile_is_started(): void
    {
        Sanctum::actingAs(User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]));

        $this->getJson('/api/v1/onboarding/readiness')
            ->assertOk()
            ->assertJsonPath('data.readiness.is_ready', false)
            ->assertJsonPath('data.readiness.missing_requirements', [
                'profile', 'religion', 'cover_photo', 'clear_face_photo',
            ]);
    }

    public function test_reports_ready_after_all_required_profile_inputs_are_approved(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);
        $profile = UserProfile::factory()->for($user)->create();
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

        $this->getJson('/api/v1/onboarding/readiness')
            ->assertOk()
            ->assertJsonPath('data.readiness.is_ready', true)
            ->assertJsonPath('data.readiness.missing_requirements', []);
    }
}
