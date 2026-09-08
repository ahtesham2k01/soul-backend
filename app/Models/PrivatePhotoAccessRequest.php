<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class PrivatePhotoAccessRequest extends Model
{
    protected $fillable = ['match_id', 'owner_user_id', 'requester_user_id', 'status', 'decided_at', 'revoked_at'];

    public function match(): BelongsTo
    {
        return $this->belongsTo(UserMatch::class, 'match_id');
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_user_id');
    }

    protected static function booted(): void
    {
        static::creating(fn (self $request) => $request->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['decided_at' => 'immutable_datetime', 'revoked_at' => 'immutable_datetime'];
    }
}
