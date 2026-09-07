<?php

namespace Tests\Feature\Api\V1\Matching;

use App\Models\Conversation;
use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LikeRequestAndPresenceEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_pending_likes_are_listed_and_can_be_accepted_into_one_match(): void
    {
        [$sender, $recipient] = $this->liveUsers();
        ProfileDecision::query()->create([
            'actor_user_id' => $sender->id, 'target_user_id' => $recipient->id, 'decision' => 'like',
        ]);
        Sanctum::actingAs($recipient);

        $this->getJson('/api/v1/likes/received')->assertOk()
            ->assertJsonCount(1, 'data.requests')
            ->assertJsonPath('data.requests.0.profile.id', $sender->profile->public_id);

        $matchId = $this->putJson("/api/v1/profiles/{$sender->profile->public_id}/like", ['decision' => 'accept'])
            ->assertOk()->assertJsonPath('data.matched', true)->json('data.match_id');

        $this->assertDatabaseCount('user_matches', 1);
        $this->getJson('/api/v1/likes/received')->assertJsonCount(0, 'data.requests');
        $this->putJson("/api/v1/profiles/{$sender->profile->public_id}/like", ['decision' => 'accept'])
            ->assertNotFound();
        $this->assertNotNull($matchId);
    }

    public function test_pending_like_can_be_declined_without_creating_a_match(): void
    {
        [$sender, $recipient] = $this->liveUsers();
        ProfileDecision::query()->create([
            'actor_user_id' => $sender->id, 'target_user_id' => $recipient->id, 'decision' => 'like',
        ]);
        Sanctum::actingAs($recipient);

        $this->putJson("/api/v1/profiles/{$sender->profile->public_id}/like", ['decision' => 'decline'])
            ->assertOk()->assertJsonPath('data.matched', false);

        $this->assertDatabaseCount('user_matches', 0);
        $this->assertDatabaseHas('profile_decisions', [
            'actor_user_id' => $recipient->id, 'target_user_id' => $sender->id, 'decision' => 'pass',
        ]);
        $this->getJson('/api/v1/likes/received')->assertJsonCount(0, 'data.requests');
    }

    public function test_sender_can_withdraw_only_a_pending_like(): void
    {
        [$sender, $recipient] = $this->liveUsers();
        ProfileDecision::query()->create([
            'actor_user_id' => $sender->id, 'target_user_id' => $recipient->id, 'decision' => 'like',
        ]);
        Sanctum::actingAs($sender);

        $url = "/api/v1/profiles/{$recipient->profile->public_id}/like";
        $this->deleteJson($url)->assertOk()->assertJsonPath('data.withdrawn', true);
        $this->deleteJson($url)->assertOk();
        $this->assertDatabaseCount('profile_decisions', 0);

        $ids = [$sender->id, $recipient->id];
        sort($ids);
        UserMatch::query()->create([
            'first_user_id' => $ids[0], 'second_user_id' => $ids[1], 'status' => 'active', 'matched_at' => now(),
        ]);
        ProfileDecision::query()->create([
            'actor_user_id' => $sender->id, 'target_user_id' => $recipient->id, 'decision' => 'like',
        ]);
        $this->deleteJson($url)->assertConflict()->assertJsonPath('error.code', 'LIKE_ALREADY_MATCHED');
    }

    public function test_blocked_and_suspended_senders_are_hidden_from_received_likes(): void
    {
        [$sender, $recipient] = $this->liveUsers();
        ProfileDecision::query()->create([
            'actor_user_id' => $sender->id, 'target_user_id' => $recipient->id, 'decision' => 'like',
        ]);
        $sender->forceFill(['status' => User::STATUS_SUSPENDED])->save();
        Sanctum::actingAs($recipient);

        $this->getJson('/api/v1/likes/received')->assertOk()->assertJsonCount(0, 'data.requests');
        $this->putJson("/api/v1/profiles/{$sender->profile->public_id}/like", ['decision' => 'accept'])
            ->assertNotFound();
    }

    public function test_match_list_contains_presence_latest_message_and_unread_count(): void
    {
        [$first, $second, $match] = $this->matchedUsers();
        $second->profile->update(['last_active_at' => now()]);
        $conversation = Conversation::query()->create(['user_match_id' => $match->id, 'last_message_at' => now()]);
        $message = $conversation->messages()->create(['sender_user_id' => $second->id, 'body' => 'Salam']);
        Sanctum::actingAs($first);

        $this->getJson('/api/v1/matches')->assertOk()
            ->assertJsonPath('data.matches.0.presence.is_online', true)
            ->assertJsonPath('data.matches.0.conversation.last_message.id', $message->public_id)
            ->assertJsonPath('data.matches.0.conversation.unread_count', 1);
    }

    public function test_typing_signal_is_match_bound_short_lived_and_clearable(): void
    {
        [$first, $second, $match] = $this->matchedUsers();
        Sanctum::actingAs($first);
        $this->putJson("/api/v1/matches/{$match->public_id}/typing", ['is_typing' => true])
            ->assertOk()->assertJsonPath('data.typing_expires_in_seconds', 8);
        $this->assertTrue(Cache::has("chat:{$match->public_id}:typing:{$first->id}"));

        Sanctum::actingAs($second);
        $this->getJson("/api/v1/matches/{$match->public_id}/presence")
            ->assertOk()->assertJsonPath('data.is_typing', true);

        Sanctum::actingAs($first);
        $this->putJson("/api/v1/matches/{$match->public_id}/typing", ['is_typing' => false])
            ->assertOk()->assertJsonPath('data.is_typing', false);
        $this->assertFalse(Cache::has("chat:{$match->public_id}:typing:{$first->id}"));
    }

    public function test_outsider_cannot_read_or_write_match_presence(): void
    {
        [, , $match] = $this->matchedUsers();
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));

        $this->getJson("/api/v1/matches/{$match->public_id}/presence")->assertNotFound();
        $this->putJson("/api/v1/matches/{$match->public_id}/typing", ['is_typing' => true])->assertNotFound();
    }

    private function liveUsers(): array
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($first)->create(['profile_status' => 'live']);
        UserProfile::factory()->for($second)->create(['profile_status' => 'live']);

        return [$first->load('profile'), $second->load('profile')];
    }

    private function matchedUsers(): array
    {
        [$first, $second] = $this->liveUsers();
        $ids = [$first->id, $second->id];
        sort($ids);
        $match = UserMatch::query()->create([
            'first_user_id' => $ids[0], 'second_user_id' => $ids[1], 'status' => 'active', 'matched_at' => now(),
        ]);

        return [$first, $second, $match];
    }
}
