<?php

namespace Tests\Feature\Api\V1\Safety;

use App\Models\AccountAppeal;
use App\Models\ProfileDecision;
use App\Models\ProfileVerificationCase;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SafetyCompletionEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_report_and_block_is_one_atomic_action_that_closes_interaction(): void
    {
        [$reporter, $target, $match] = $this->matchedUsers();
        ProfileDecision::query()->create(['actor_user_id' => $reporter->id, 'target_user_id' => $target->id, 'decision' => 'like']);
        Sanctum::actingAs($reporter);

        $this->postJson("/api/v1/profiles/{$target->profile->public_id}/report", [
            'category' => 'harassment', 'details' => 'Repeated unwanted contact', 'action' => 'report_and_block',
        ])->assertCreated()->assertJsonPath('data.blocked', true)->assertJsonPath('data.action', 'report_and_block');

        $this->assertDatabaseHas('user_reports', ['reported_user_id' => $target->id, 'reporter_action' => 'report_and_block']);
        $this->assertDatabaseHas('user_blocks', ['blocker_user_id' => $reporter->id, 'blocked_user_id' => $target->id]);
        $this->assertDatabaseHas('user_matches', ['id' => $match->id, 'status' => 'blocked']);
        $this->assertDatabaseCount('profile_decisions', 0);
    }

    public function test_underage_report_immediately_pauses_profile_and_requires_identity_review(): void
    {
        [$reporter, $target] = $this->matchedUsers();
        ProfileVerificationCase::query()->create([
            'user_id' => $target->id, 'type' => 'identity', 'requirement' => 'optional',
            'status' => 'pending', 'submitted_at' => now(),
        ]);
        Sanctum::actingAs($reporter);

        $this->postJson("/api/v1/profiles/{$target->profile->public_id}/report", [
            'category' => 'underage', 'action' => 'report_only',
        ])->assertCreated()->assertJsonPath('data.blocked', false);

        $this->assertSame('paused_verification', $target->profile->refresh()->profile_status->value);
        $this->assertDatabaseHas('safety_cases', ['user_id' => $target->id, 'type' => 'underage_suspicion', 'severity' => 'critical', 'status' => 'open']);
        $this->assertDatabaseHas('profile_verification_cases', ['user_id' => $target->id, 'type' => 'identity', 'requirement' => 'required', 'status' => 'pending']);
        $this->assertDatabaseCount('profile_verification_cases', 1);
    }

    public function test_moderator_can_pause_report_and_resolve_safety_case_with_audit(): void
    {
        [$reporter, $target] = $this->matchedUsers();
        Sanctum::actingAs($reporter);
        $reportId = $this->postJson("/api/v1/profiles/{$target->profile->public_id}/report", [
            'category' => 'scam', 'details' => 'Suspicious payment request',
        ])->assertCreated()->json('data.report_id');

        $moderator = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $moderator->forceFill(['admin_role' => 'moderator'])->save();
        Sanctum::actingAs($moderator);
        $this->putJson("/api/v1/admin/reports/{$reportId}", [
            'decision' => 'pause_for_review', 'reason' => 'Manual risk review is required',
        ])->assertOk()->assertJsonPath('data.status', 'under_review');
        $caseId = $this->getJson('/api/v1/admin/safety-cases')->assertOk()->json('data.cases.0.id');
        $this->putJson("/api/v1/admin/safety-cases/{$caseId}", [
            'decision' => 'verification_required', 'reason' => 'Identity evidence is required',
        ])->assertOk()->assertJsonPath('data.status', 'verification_required');

        $this->assertSame('paused_verification', $target->profile->refresh()->profile_status->value);
        $this->assertDatabaseHas('profile_verification_cases', ['user_id' => $target->id, 'requirement' => 'required']);
        $this->assertDatabaseHas('admin_audit_logs', ['action' => 'safety_case.verification_required']);
    }

    public function test_only_blocked_account_gets_one_idempotent_appeal(): void
    {
        $active = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($active);
        $this->postJson('/api/v1/account-appeal', ['statement' => 'Please review this account restriction carefully.'])->assertConflict();

        $blocked = User::factory()->create(['status' => User::STATUS_BLOCKED]);
        Sanctum::actingAs($blocked);
        $id = $this->postJson('/api/v1/account-appeal', ['statement' => 'Please review this account restriction carefully.'])
            ->assertStatus(202)->json('data.appeal.id');
        $this->postJson('/api/v1/account-appeal', ['statement' => 'A changed statement cannot create another appeal.'])
            ->assertStatus(202)->assertJsonPath('data.appeal.id', $id);
        $this->getJson('/api/v1/account-appeal')->assertOk()->assertJsonPath('data.appeal.status', 'pending')
            ->assertJsonMissingPath('data.appeal.resolution_reason');
        $this->assertDatabaseCount('account_appeals', 1);
    }

    public function test_super_admin_can_accept_appeal_once_and_action_is_audited(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_BLOCKED]);
        $appeal = AccountAppeal::query()->create([
            'user_id' => $user->id, 'statement' => 'Please review the restriction.', 'status' => 'pending', 'submitted_at' => now(),
        ]);
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $admin->forceFill(['admin_role' => 'super_admin'])->save();
        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/admin/account-appeals')->assertOk()->assertJsonPath('data.appeals.0.id', $appeal->public_id);
        $this->putJson("/api/v1/admin/account-appeals/{$appeal->public_id}", [
            'decision' => 'accepted', 'reason' => 'Restriction reviewed and overturned',
        ])->assertOk()->assertJsonPath('data.status', 'accepted');

        $this->assertSame(User::STATUS_ACTIVE, $user->refresh()->status);
        $this->assertDatabaseHas('admin_audit_logs', ['action' => 'account_appeal.accepted', 'subject_id' => $appeal->id]);
        $this->putJson("/api/v1/admin/account-appeals/{$appeal->public_id}", [
            'decision' => 'accepted', 'reason' => 'Cannot decide twice',
        ])->assertNotFound();
    }

    private function matchedUsers(): array
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($first)->create(['profile_status' => 'live']);
        UserProfile::factory()->for($second)->create(['profile_status' => 'live']);
        $ids = [$first->id, $second->id];
        sort($ids);
        $match = UserMatch::query()->create(['first_user_id' => $ids[0], 'second_user_id' => $ids[1], 'status' => 'active', 'matched_at' => now()]);

        return [$first->load('profile'), $second->load('profile'), $match];
    }
}
