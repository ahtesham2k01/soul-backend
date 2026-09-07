<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Feature extends Model
{
    protected $fillable = ['key', 'name', 'description', 'access_mode', 'is_enabled', 'daily_limit', 'monthly_limit', 'rollout_percentage', 'starts_at', 'ends_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['is_enabled' => 'boolean', 'starts_at' => 'immutable_datetime', 'ends_at' => 'immutable_datetime'];
    }
}
