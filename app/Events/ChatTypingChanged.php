<?php

namespace App\Events;

use App\Models\User;
use App\Models\UserMatch;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatTypingChanged implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public UserMatch $match, public User $user, public bool $typing, public ?string $expiresAt) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('match.'.$this->match->public_id)];
    }

    public function broadcastAs(): string
    {
        return 'chat.typing.changed';
    }

    public function broadcastWith(): array
    {
        return ['match_id' => $this->match->public_id, 'user_id' => $this->user->public_id, 'typing' => $this->typing, 'expires_at' => $this->expiresAt];
    }
}
