<?php

namespace Tests\Feature\Api\V1\Safety;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Models\ProfilePhoto;
use App\Models\ProfileVerificationCase;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileVerificationEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_verification_endpoints_require_authentication(): void
    {
        $this->getJson('/api/v1/verification/cases')->assertUnauthorized();
        $this->postJson('/api/v1/verification/cases')->assertUnauthorized();
    }

    public function test_clear_approved_face_is_required_and_open_request_is_idempotent(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);
        $this->postJson('/api/v1/verification/cases', ['type' => 'identity'])
            ->assertUnprocessable()->assertJsonPath('error.code', 'VERIFICATION_NOT_READY');
        ProfilePhoto::factory()->for($profile)->create([
            'moderation_status' => ProfilePhotoModerationStatus::Approved, 'face_detected' => true,
        ]);
        $first = $this->postJson('/api/v1/verification/cases', ['type' => 'identity'])
            ->assertStatus(202)->json('data.verification_case.id');
        $this->postJson('/api/v1/verification/cases', ['type' => 'identity'])
            ->assertStatus(202)->assertJsonPath('data.verification_case.id', $first);
        $this->assertDatabaseCount('profile_verification_cases', 1);
    }

    public function test_only_owner_sees_case_and_reason_without_internal_ids(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $case = ProfileVerificationCase::query()->create([
            'user_id' => $user->id, 'type' => 'identity', 'status' => 'appeal_available',
            'reason' => 'Identity details could not be confirmed.', 'submitted_at' => now(), 'reviewed_at' => now(),
        ]);
        Sanctum::actingAs($user);
        $this->getJson('/api/v1/verification/cases')->assertOk()
            ->assertJsonPath('data.verification_cases.0.id', $case->public_id)
            ->assertJsonMissingPath('data.verification_cases.0.user_id');
    }

    public function test_appeal_is_owner_only_state_gated_and_idempotent(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $case = ProfileVerificationCase::query()->create([
            'user_id' => $user->id, 'type' => 'identity',
            'status' => 'appeal_available', 'submitted_at' => now(),
        ]);
        $other = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($other);
        $url = "/api/v1/verification/cases/{$case->public_id}/appeal";
        $this->postJson($url, ['statement' => str_repeat('a', 25)])->assertNotFound();
        Sanctum::actingAs($user);
        $appealId = $this->postJson($url, ['statement' => 'Please review my identity again.'])
            ->assertStatus(202)->json('data.appeal.id');
        $this->postJson($url, ['statement' => 'Please review my identity again.'])
            ->assertStatus(202)->assertJsonPath('data.appeal.id', $appealId);
        $this->assertDatabaseCount('verification_appeals', 1);
        $this->assertSame('appeal_pending', $case->refresh()->status);
    }
}
