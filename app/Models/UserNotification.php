<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class UserNotification extends Model
{
    protected $fillable = ['user_id', 'broadcast_id', 'type', 'deduplication_key', 'data', 'delivery_channels', 'read_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['data' => 'array', 'delivery_channels' => 'array', 'read_at' => 'immutable_datetime'];
    }
}
