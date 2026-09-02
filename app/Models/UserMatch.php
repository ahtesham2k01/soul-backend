<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class UserMatch extends Model
{
    protected $fillable = [
        'first_user_id', 'second_user_id', 'status', 'matched_at',
        'ended_at', 'ended_by_user_id',
    ];

    public function firstUser(): BelongsTo { return $this->belongsTo(User::class, 'first_user_id'); }
    public function secondUser(): BelongsTo { return $this->belongsTo(User::class, 'second_user_id'); }

    protected static function booted(): void
    {
        static::creating(fn (UserMatch $match) => $match->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['matched_at' => 'immutable_datetime', 'ended_at' => 'immutable_datetime'];
    }
}
