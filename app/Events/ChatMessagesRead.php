<?php

namespace App\Events;

use App\Models\User;
use App\Models\UserMatch;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatMessagesRead implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public UserMatch $match, public User $reader, public int $count, public string $readAt) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('match.'.$this->match->public_id)];
    }

    public function broadcastAs(): string
    {
        return 'chat.messages.read';
    }

    public function broadcastWith(): array
    {
        return ['match_id' => $this->match->public_id, 'reader_id' => $this->reader->public_id, 'count' => $this->count, 'read_at' => $this->readAt];
    }
}
