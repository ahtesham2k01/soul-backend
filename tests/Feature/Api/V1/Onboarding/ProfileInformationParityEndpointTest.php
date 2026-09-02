<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileInformationParityEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_complete_required_answer_options_and_optional_profile_details_are_saved(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/onboarding/profile', [
            'marital_status' => 'married',
            'profession_status' => 'self_employed',
            'smoking' => 'occasionally',
            'alcohol' => 'prefer_not_to_say',
            'current_children' => 'yes_living_with_me',
            'future_children' => 'not_sure',
            'bio' => 'I enjoy books and long walks.',
            'education' => 'Bachelor degree',
            'height_cm' => 168,
            'job_title' => 'Designer',
            'employer' => 'Studio',
            'grew_up_in' => 'Karachi',
            'ethnic_origin' => 'South Asian',
            'religious_practice' => 'Practising',
            'prayer' => 'Daily',
            'diet' => 'Halal',
            'dress' => 'Modest',
            'detailed_religion_visible' => false,
            'relocation_preference' => 'open_to_relocation',
            'family_involvement_preference' => 'early',
            'interests' => ['Reading', 'Travel'],
            'personality_traits' => ['Kind', 'Curious'],
        ])->assertOk()
            ->assertJsonPath('data.profile.marital_status', 'married')
            ->assertJsonPath('data.profile.religious_practice', 'Practising')
            ->assertJsonPath('data.profile.detailed_religion_visible', false)
            ->assertJsonPath('data.profile.interests', ['Reading', 'Travel'])
            ->assertJsonPath('data.profile.personality_traits', ['Kind', 'Curious'])
            ->assertJsonPath('data.profile.prefer_not_to_say_fields', []);

        $this->assertDatabaseHas('user_profiles', [
            'user_id' => $user->id,
            'marital_status' => 'married',
            'religious_practice' => 'Practising',
            'detailed_religion_visible' => false,
        ]);
        $this->assertDatabaseCount('user_profile_interests', 2);
        $this->assertDatabaseCount('user_profile_traits', 2);
    }

    public function test_skip_and_prefer_not_to_say_remain_distinct_and_can_be_changed(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/onboarding/profile', [
            'education' => null,
            'prefer_not_to_say_fields' => ['height_cm', 'interests'],
        ])->assertOk()
            ->assertJsonPath('data.profile.education', null)
            ->assertJsonPath('data.profile.height_cm', null)
            ->assertJsonPath('data.profile.interests', [])
            ->assertJsonPath('data.profile.prefer_not_to_say_fields', ['height_cm', 'interests']);

        $this->putJson('/api/v1/onboarding/profile', [
            'height_cm' => 172,
            'interests' => ['Cooking'],
        ])->assertOk()
            ->assertJsonPath('data.profile.height_cm', 172)
            ->assertJsonPath('data.profile.interests', ['Cooking'])
            ->assertJsonPath('data.profile.prefer_not_to_say_fields', []);

        $this->getJson('/api/v1/onboarding/profile')->assertOk()
            ->assertJsonPath('data.profile.height_cm', 172)
            ->assertJsonPath('data.profile.interests', ['Cooking']);
    }

    public function test_answer_and_prefer_not_to_say_cannot_conflict(): void
    {
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));

        $this->putJson('/api/v1/onboarding/profile', [
            'education' => 'Master degree',
            'prefer_not_to_say_fields' => ['education'],
        ])->assertUnprocessable()->assertJsonStructure([
            'error' => ['details' => ['fields' => ['education']]],
        ]);
    }

    public function test_interest_trait_and_enum_limits_are_enforced(): void
    {
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));

        $this->putJson('/api/v1/onboarding/profile', [
            'marital_status' => 'secret',
            'profession_status' => 'influencer',
            'smoking' => 'sometimes_maybe',
            'current_children' => 'none',
            'future_children' => 'later',
            'interests' => collect(range(1, 16))->map(fn (int $number): string => "Interest {$number}")->all(),
            'personality_traits' => collect(range(1, 6))->map(fn (int $number): string => "Trait {$number}")->all(),
        ])->assertUnprocessable()->assertJsonStructure([
            'error' => ['details' => ['fields' => [
                'marital_status', 'profession_status', 'smoking', 'current_children',
                'future_children', 'interests', 'personality_traits',
            ]]],
        ]);
    }

    public function test_profile_deletion_cascades_new_normalized_details(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = $user->profile()->create(['first_name' => 'Ayesha']);
        $profile->interests()->create(['value' => 'Reading']);
        $profile->personalityTraits()->create(['value' => 'Kind']);
        $profile->withheldFields()->create(['field' => 'education']);

        $profile->delete();

        $this->assertDatabaseCount('user_profile_interests', 0);
        $this->assertDatabaseCount('user_profile_traits', 0);
        $this->assertDatabaseCount('user_profile_withheld_fields', 0);
    }
}
