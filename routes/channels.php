<?php

use App\Models\User;
use App\Models\UserMatch;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('match.{matchId}', function (User $user, string $matchId): bool {
    return UserMatch::query()->where('public_id', $matchId)->where('status', 'active')
        ->where(fn ($query) => $query->where('first_user_id', $user->id)->orWhere('second_user_id', $user->id))
        ->whereHas('firstUser', fn ($query) => $query->where('status', User::STATUS_ACTIVE))
        ->whereHas('secondUser', fn ($query) => $query->where('status', User::STATUS_ACTIVE))->exists();
});
