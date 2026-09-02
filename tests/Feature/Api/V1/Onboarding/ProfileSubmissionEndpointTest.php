<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Enums\Profile\RelationshipIntention;
use App\Enums\Profile\ReligionNodeType;
use App\Jobs\RunProfileAutomatedChecks;
use App\Models\ProfilePhoto;
use App\Models\ReligionTaxonomyNode;
use App\Models\SpokenLanguage;
use App\Models\User;
use App\Models\UserProfile;
use App\Models\UserProfileIntention;
use App\Models\UserReligionProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileSubmissionEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_submission_and_status_endpoints_require_authentication(): void
    {
        $this->postJson('/api/v1/onboarding/submit')->assertUnauthorized();
        $this->postJson('/api/v1/onboarding/resubmit')->assertUnauthorized();
        $this->getJson('/api/v1/onboarding/status')->assertUnauthorized();
    }

    public function test_incomplete_profile_cannot_be_submitted(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/onboarding/submit', $this->acceptancePayload())
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'ONBOARDING_INCOMPLETE')
            ->assertJsonPath('error.details.missing_requirements.0', 'profile');
        $this->assertDatabaseCount('legal_acceptances', 0);
    }

    public function test_current_legal_document_versions_must_be_explicitly_accepted(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $this->makeReady($user);
        Sanctum::actingAs($user);
        $payload = $this->acceptancePayload();
        $payload['terms_version'] = 'outdated';

        $this->postJson('/api/v1/onboarding/submit', $payload)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');
    }

    public function test_submits_ready_profile_records_legal_audit_and_queues_checks(): void
    {
        Bus::fake();
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = $this->makeReady($user);
        Sanctum::actingAs($user);

        $this->withHeader('User-Agent', 'SOUL-Flutter/1.0')
            ->postJson('/api/v1/onboarding/submit', $this->acceptancePayload())
            ->assertStatus(202)
            ->assertJsonPath('data.profile.status', 'submitted')
            ->assertJsonPath('data.profile.reason', null);

        $this->assertDatabaseHas('legal_acceptances', [
            'user_id' => $user->id,
            'document_type' => 'terms',
            'document_version' => '1.0',
        ]);
        $this->assertDatabaseHas('legal_acceptances', [
            'user_id' => $user->id,
            'document_type' => 'privacy',
            'document_version' => '1.0',
        ]);
        $this->assertDatabaseHas('user_profiles', [
            'id' => $profile->id,
            'profile_status' => 'submitted',
        ]);
        Bus::assertDispatched(
            RunProfileAutomatedChecks::class,
            fn (RunProfileAutomatedChecks $job): bool => $job->profileId === $profile->id,
        );

        (new RunProfileAutomatedChecks($profile->id))
            ->handle(app(\App\Support\Onboarding\ProfileReadiness::class));
        $this->getJson('/api/v1/onboarding/status')
            ->assertOk()
            ->assertJsonPath('data.profile.status', 'live')
            ->assertJsonPath('data.profile.reason', null);
    }

    public function test_repeated_submission_is_idempotent(): void
    {
        Bus::fake();
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $this->makeReady($user);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/onboarding/submit', $this->acceptancePayload())
            ->assertStatus(202);
        $this->postJson('/api/v1/onboarding/submit', $this->acceptancePayload())
            ->assertStatus(202);

        $this->assertDatabaseCount('legal_acceptances', 2);
        Bus::assertDispatchedTimes(RunProfileAutomatedChecks::class, 1);
    }

    public function test_only_changes_required_profile_can_be_resubmitted(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $this->makeReady($user);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/onboarding/resubmit')
            ->assertConflict()
            ->assertJsonPath('error.code', 'PROFILE_NOT_CORRECTABLE');
    }

    public function test_profile_cannot_be_resubmitted_until_corrections_are_complete(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create([
            'profile_status' => 'changes_required',
            'status_reason' => 'Add a suitable cover photo.',
            'correction_screen' => 'onboarding.photos',
        ]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/onboarding/resubmit')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'CORRECTIONS_INCOMPLETE');
    }

    public function test_corrected_profile_is_resubmitted_and_lifecycle_history_is_returned(): void
    {
        Bus::fake();
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = $this->makeReady($user);
        $profile->update([
            'profile_status' => 'changes_required',
            'status_reason' => 'Replace the rejected photo.',
            'correction_screen' => 'onboarding.photos',
        ]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/onboarding/resubmit')
            ->assertStatus(202)
            ->assertJsonPath('data.profile.status', 'submitted')
            ->assertJsonPath('data.profile.reason', null);

        Bus::assertDispatched(
            RunProfileAutomatedChecks::class,
            fn (RunProfileAutomatedChecks $job): bool => $job->profileId === $profile->id,
        );
        $this->assertDatabaseHas('profile_status_transitions', [
            'user_profile_id' => $profile->id,
            'actor_user_id' => $user->id,
            'from_status' => 'changes_required',
            'to_status' => 'submitted',
            'source' => 'api.v1.onboarding.resubmit',
        ]);

        $this->getJson('/api/v1/onboarding/status')
            ->assertOk()
            ->assertJsonPath('data.profile.history.0.from', 'changes_required')
            ->assertJsonPath('data.profile.history.0.to', 'submitted')
            ->assertJsonPath('data.profile.history.0.source', 'api.v1.onboarding.resubmit');
    }

    private function makeReady(User $user): UserProfile
    {
        $profile = UserProfile::factory()->for($user)->create();
        $profile->spokenLanguages()->attach(SpokenLanguage::factory()->create());
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

        return $profile;
    }

    private function acceptancePayload(): array
    {
        return [
            'terms_accepted' => true,
            'terms_version' => '1.0',
            'privacy_accepted' => true,
            'privacy_version' => '1.0',
            'device_id' => 'test-device',
        ];
    }
}
