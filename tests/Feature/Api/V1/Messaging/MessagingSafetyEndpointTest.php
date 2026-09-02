<?php

namespace Tests\Feature\Api\V1\Messaging;

use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MessagingSafetyEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_active_match_participants_can_send_and_read_messages(): void
    {
        [$first, $second, $match] = $this->matchedUsers();
        Sanctum::actingAs($first);
        $message = $this->postJson("/api/v1/matches/{$match->public_id}/messages", ['body' => ' Salam '])
            ->assertCreated()->assertJsonPath('data.message.body', 'Salam')->json('data.message.id');
        Sanctum::actingAs($second);
        $this->getJson("/api/v1/matches/{$match->public_id}/messages")
            ->assertOk()->assertJsonPath('data.messages.0.id', $message)
            ->assertJsonPath('data.messages.0.is_mine', false);
        $outsider = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($outsider);
        $this->getJson("/api/v1/matches/{$match->public_id}/messages")->assertNotFound();
    }

    public function test_unmatched_users_cannot_continue_messaging(): void
    {
        [$first, , $match] = $this->matchedUsers();
        $match->update(['status' => 'unmatched', 'ended_at' => now(), 'ended_by_user_id' => $first->id]);
        Sanctum::actingAs($first);
        $this->postJson("/api/v1/matches/{$match->public_id}/messages", ['body' => 'Hello'])->assertNotFound();
    }

    public function test_recipient_can_mark_messages_read_and_receipt_is_visible_to_sender(): void
    {
        [$first, $second, $match] = $this->matchedUsers();
        Sanctum::actingAs($first);
        $messageId = $this->postJson("/api/v1/matches/{$match->public_id}/messages", ['body' => 'Hello'])
            ->assertCreated()->json('data.message.id');
        Sanctum::actingAs($second);
        $this->postJson("/api/v1/matches/{$match->public_id}/messages/read")
            ->assertOk()->assertJsonPath('data.marked_read', 1);
        $this->postJson("/api/v1/matches/{$match->public_id}/messages/read")
            ->assertOk()->assertJsonPath('data.marked_read', 0);
        Sanctum::actingAs($first);
        $this->getJson("/api/v1/matches/{$match->public_id}/messages")
            ->assertOk()->assertJsonPath('data.messages.0.id', $messageId)
            ->assertJsonPath('data.messages.0.is_mine', true)
            ->assertJson(fn ($json) => $json->whereType('data.messages.0.read_at', 'string')->etc());
    }

    public function test_active_user_cannot_message_a_suspended_match(): void
    {
        [$first, $second, $match] = $this->matchedUsers();
        $second->forceFill(['status' => 'suspended'])->save();
        Sanctum::actingAs($first);

        $this->getJson("/api/v1/matches/{$match->public_id}/messages")
            ->assertNotFound();
        $this->postJson("/api/v1/matches/{$match->public_id}/messages", [
            'body' => 'Hello',
        ])->assertNotFound();

        $this->assertDatabaseCount('messages', 0);
    }

    public function test_block_is_idempotent_closes_match_and_removes_decisions(): void
    {
        [$first, $second, $match] = $this->matchedUsers();
        ProfileDecision::query()->create([
            'actor_user_id' => $first->id, 'target_user_id' => $second->id, 'decision' => 'like',
        ]);
        Sanctum::actingAs($first);
        $url = "/api/v1/profiles/{$second->profile->public_id}/block";
        $this->postJson($url, ['reason' => 'Harassment'])->assertOk()->assertJsonPath('data.blocked', true);
        $this->postJson($url)->assertOk();
        $this->assertDatabaseCount('user_blocks', 1);
        $this->assertDatabaseMissing('user_matches', ['id' => $match->id, 'status' => 'active']);
        $this->assertDatabaseCount('profile_decisions', 0);
        $this->postJson("/api/v1/profiles/{$second->profile->public_id}/decision", ['decision' => 'like'])->assertNotFound();
    }

    public function test_report_validation_and_safe_receipt_contract(): void
    {
        [$first, $second] = $this->matchedUsers();
        Sanctum::actingAs($first);
        $url = "/api/v1/profiles/{$second->profile->public_id}/report";
        $this->postJson($url, ['category' => 'invalid'])->assertUnprocessable();
        $this->postJson($url, ['category' => 'harassment', 'details' => 'Repeated threats'])
            ->assertCreated()->assertJsonPath('data.status', 'pending')
            ->assertJsonMissingPath('data.reported_user_id');
        $this->assertDatabaseHas('user_reports', [
            'reporter_user_id' => $first->id, 'reported_user_id' => $second->id,
            'category' => 'harassment', 'status' => 'pending',
        ]);
        $this->postJson($url, ['category' => 'nudity_sexual_content'])->assertCreated();
        $this->postJson($url, ['category' => 'false_marital_status'])->assertCreated();
        $this->postJson($url, ['category' => 'inappropriate_content'])->assertUnprocessable();
    }

    private function matchedUsers(): array
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($first)->create(['profile_status' => 'live']);
        UserProfile::factory()->for($second)->create(['profile_status' => 'live']);
        $ids = [$first->id, $second->id];
        sort($ids);
        $match = UserMatch::query()->create([
            'first_user_id' => $ids[0], 'second_user_id' => $ids[1],
            'status' => 'active', 'matched_at' => now(),
        ]);

        return [$first->load('profile'), $second->load('profile'), $match];
    }
}
