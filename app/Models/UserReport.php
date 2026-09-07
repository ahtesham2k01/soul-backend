<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class UserReport extends Model
{
    protected $fillable = ['reporter_user_id', 'reported_user_id', 'category', 'details', 'reporter_action', 'status', 'reviewed_at', 'reviewed_by_admin_id'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    public function reportedUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_user_id');
    }
}
