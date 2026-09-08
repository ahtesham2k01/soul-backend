<?php

namespace Tests\Feature\Api\V1\Matching;

use App\Events\ChatMessageCreated;
use App\Events\ChatMessagesRead;
use App\Events\ChatTypingChanged;
use App\Models\Conversation;
use App\Models\User;
use App\Models\UserMatch;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RealtimeChatEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_message_read_receipt_and_typing_emit_realtime_events(): void
    {
        Event::fake([ChatMessageCreated::class, ChatMessagesRead::class, ChatTypingChanged::class]);
        [$first, $second, $match] = $this->matchedUsers();
        Sanctum::actingAs($first);
        $this->postJson("/api/v1/matches/{$match->public_id}/messages", ['body' => 'Realtime salam'])->assertCreated();
        $this->putJson("/api/v1/matches/{$match->public_id}/typing", ['is_typing' => true])->assertOk();
        Event::assertDispatched(ChatMessageCreated::class, fn ($event) => $event->match->is($match) && $event->sender->is($first));
        Event::assertDispatched(ChatTypingChanged::class, fn ($event) => $event->typing && $event->user->is($first));

        Sanctum::actingAs($second);
        $this->postJson("/api/v1/matches/{$match->public_id}/messages/read")->assertOk()->assertJsonPath('data.marked_read', 1);
        Event::assertDispatched(ChatMessagesRead::class, fn ($event) => $event->count === 1 && $event->reader->is($second));
    }

    public function test_only_match_members_can_authorize_private_realtime_channel(): void
    {
        [$first, , $match] = $this->matchedUsers();
        Sanctum::actingAs($first);
        $this->getJson('/api/v1/matches/'.$match->public_id.'/realtime')->assertOk()
            ->assertJsonPath('data.channel', 'private-match.'.$match->public_id)
            ->assertJsonPath('data.events.0', 'chat.message.created');

        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));
        $this->getJson('/api/v1/matches/'.$match->public_id.'/realtime')->assertNotFound();
    }

    public function test_realtime_payload_never_contains_internal_database_ids(): void
    {
        [$first, , $match] = $this->matchedUsers();
        $conversation = Conversation::create(['user_match_id' => $match->id]);
        $message = $conversation->messages()->create(['sender_user_id' => $first->id, 'body' => 'Safe payload']);
        $payload = (new ChatMessageCreated($match, $message, $first))->broadcastWith();
        $this->assertSame($first->public_id, $payload['message']['sender_id']);
        $this->assertArrayNotHasKey('user_id', $payload['message']);
        $this->assertArrayNotHasKey('conversation_id', $payload['message']);
    }

    private function matchedUsers(): array
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $ids = [$first->id, $second->id];
        sort($ids);
        $match = UserMatch::create(['first_user_id' => $ids[0], 'second_user_id' => $ids[1], 'status' => 'active', 'matched_at' => now()]);

        return [$first, $second, $match];
    }
}
