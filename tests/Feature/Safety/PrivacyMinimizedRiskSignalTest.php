<?php

namespace Tests\Feature\Safety;

use App\Models\Conversation;
use App\Models\ProfileDecision;
use App\Models\SafetyCase;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use App\Support\Safety\SafetyRiskMonitor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PrivacyMinimizedRiskSignalTest extends TestCase
{
    use RefreshDatabase;

    public function test_decision_velocity_coalesces_into_one_reversible_review_case(): void
    {
        config()->set('soul.safety.decision_velocity_threshold', 3);
        $actor = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($actor)->create(['profile_status' => 'live']);
        foreach (range(1, 3) as $unused) {
            $target = User::factory()->create(['status' => User::STATUS_ACTIVE]);
            ProfileDecision::query()->create([
                'actor_user_id' => $actor->id,
                'target_user_id' => $target->id,
                'decision' => 'like',
            ]);
        }

        $monitor = app(SafetyRiskMonitor::class);
        $monitor->observeDecisionVelocity($actor);
        $monitor->observeDecisionVelocity($actor);

        $case = SafetyCase::query()->sole();
        $this->assertSame('suspicious_decision_velocity', $case->type);
        $this->assertSame(2, $case->occurrence_count);
        $this->assertSame(3, $case->evidence['event_count']);
        $this->assertSame('live', $actor->profile->refresh()->profile_status->value);
        $this->assertSame(64, strlen($case->signal_key));
    }

    public function test_repeated_message_evidence_never_stores_message_content(): void
    {
        config()->set('soul.safety.message_velocity_threshold', 1000);
        config()->set('soul.safety.repeated_message_conversation_threshold', 5);
        $sender = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $body = 'Please contact me using this exact repeated introduction.';
        $lastMessage = null;

        foreach (range(1, 5) as $unused) {
            $recipient = User::factory()->create(['status' => User::STATUS_ACTIVE]);
            $ids = [$sender->id, $recipient->id];
            sort($ids);
            $match = UserMatch::query()->create([
                'first_user_id' => $ids[0],
                'second_user_id' => $ids[1],
                'status' => 'active',
                'matched_at' => now(),
            ]);
            $conversation = Conversation::query()->create(['user_match_id' => $match->id]);
            $lastMessage = $conversation->messages()->create([
                'sender_user_id' => $sender->id,
                'body' => $body,
            ]);
        }

        app(SafetyRiskMonitor::class)->observeMessageActivity($sender, $lastMessage);

        $case = SafetyCase::query()->where('type', 'repeated_message_pattern')->sole();
        $this->assertSame(5, $case->evidence['conversation_count']);
        $this->assertArrayNotHasKey('body', $case->evidence);
        $this->assertStringNotContainsString($body, json_encode($case->toArray(), JSON_THROW_ON_ERROR));
    }

    public function test_restricted_account_media_reuse_is_reviewable_without_automatic_enforcement(): void
    {
        $actor = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($actor)->create(['profile_status' => 'live']);
        $restricted = User::factory()->create(['status' => User::STATUS_BLOCKED]);

        app(SafetyRiskMonitor::class)->observeRepeatedMedia($actor, $restricted, 'private/provider/asset-id');

        $case = SafetyCase::query()->sole();
        $this->assertSame('possible_ban_evasion_media', $case->type);
        $this->assertTrue($case->evidence['previous_owner_restricted']);
        $this->assertStringNotContainsString('private/provider/asset-id', json_encode($case->toArray(), JSON_THROW_ON_ERROR));
        $this->assertSame(User::STATUS_ACTIVE, $actor->refresh()->status);
        $this->assertSame('live', $actor->profile->refresh()->profile_status->value);
    }

    public function test_moderator_sees_bounded_evidence_and_can_clear_a_false_positive(): void
    {
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($member)->create(['profile_status' => 'live']);
        $restricted = User::factory()->create(['status' => User::STATUS_SUSPENDED]);
        app(SafetyRiskMonitor::class)->observeRepeatedMedia($member, $restricted, 'another/private/asset');

        $moderator = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $moderator->forceFill(['admin_role' => 'moderator'])->save();
        Sanctum::actingAs($moderator);

        $response = $this->getJson('/api/v1/admin/safety-cases')
            ->assertOk()
            ->assertJsonPath('data.cases.0.type', 'possible_ban_evasion_media')
            ->assertJsonPath('data.cases.0.evidence.previous_owner_restricted', true)
            ->assertJsonPath('data.cases.0.occurrence_count', 1);

        $caseId = $response->json('data.cases.0.id');
        $this->putJson('/api/v1/admin/safety-cases/'.$caseId, [
            'decision' => 'cleared',
            'reason' => 'Reviewed as an innocent media migration.',
        ])->assertOk()->assertJsonPath('data.status', 'cleared');

        $this->assertSame('live', $member->profile->refresh()->profile_status->value);
        $this->assertDatabaseHas('admin_audit_logs', ['action' => 'safety_case.cleared']);
    }
}
