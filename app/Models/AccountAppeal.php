<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class AccountAppeal extends Model
{
    protected $fillable = ['user_id', 'statement', 'status', 'submitted_at', 'resolved_at', 'resolved_by_admin_id', 'resolution_reason'];

    protected static function booted(): void
    {
        static::creating(fn (self $appeal) => $appeal->public_id ??= (string) Str::ulid());
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return ['submitted_at' => 'immutable_datetime', 'resolved_at' => 'immutable_datetime'];
    }
}
