<?php

namespace App\Support\Safety;

use App\Models\PrivatePhotoAccessRequest;
use App\Models\ProfileDecision;
use App\Models\UserBlock;
use App\Models\UserMatch;

class CloseUserInteraction
{
    public function block(int $actorId, int $targetId, ?string $reason = null): void
    {
        UserBlock::query()->firstOrCreate(
            ['blocker_user_id' => $actorId, 'blocked_user_id' => $targetId],
            ['reason' => $reason],
        );
        UserMatch::query()->where('status', 'active')->where(fn ($query) => $query
            ->where(fn ($query) => $query->where('first_user_id', $actorId)->where('second_user_id', $targetId))
            ->orWhere(fn ($query) => $query->where('first_user_id', $targetId)->where('second_user_id', $actorId)))
            ->update(['status' => 'blocked', 'ended_at' => now(), 'ended_by_user_id' => $actorId]);
        PrivatePhotoAccessRequest::query()->whereIn('status', ['pending', 'approved'])
            ->where(fn ($query) => $query
                ->where(fn ($query) => $query->where('owner_user_id', $actorId)->where('requester_user_id', $targetId))
                ->orWhere(fn ($query) => $query->where('owner_user_id', $targetId)->where('requester_user_id', $actorId)))
            ->update(['status' => 'revoked', 'revoked_at' => now()]);
        ProfileDecision::query()->where(fn ($query) => $query
            ->where(['actor_user_id' => $actorId, 'target_user_id' => $targetId])
            ->orWhere(fn ($query) => $query->where(['actor_user_id' => $targetId, 'target_user_id' => $actorId])))->delete();
    }
}
