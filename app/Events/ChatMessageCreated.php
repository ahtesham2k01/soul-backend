<?php

namespace App\Events;

use App\Models\Message;
use App\Models\User;
use App\Models\UserMatch;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatMessageCreated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public UserMatch $match, public Message $message, public User $sender) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('match.'.$this->match->public_id)];
    }

    public function broadcastAs(): string
    {
        return 'chat.message.created';
    }

    public function broadcastWith(): array
    {
        return ['match_id' => $this->match->public_id, 'message' => ['id' => $this->message->public_id, 'sender_id' => $this->sender->public_id, 'body' => $this->message->body, 'sent_at' => $this->message->created_at->toIso8601String()]];
    }
}
