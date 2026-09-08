<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class DuplicateAccountCase extends Model
{
    protected $fillable = ['primary_user_id', 'duplicate_user_id', 'signals', 'status', 'resolution_note', 'resolved_by_admin_id', 'resolved_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $case) => $case->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['signals' => 'array', 'resolved_at' => 'immutable_datetime'];
    }

    public function primaryUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'primary_user_id');
    }

    public function duplicateUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'duplicate_user_id');
    }
}
