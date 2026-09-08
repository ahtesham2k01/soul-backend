<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class EventRegistration extends Model
{
    protected $fillable = ['event_id', 'user_id', 'joined_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['joined_at' => 'immutable_datetime'];
    }
}
