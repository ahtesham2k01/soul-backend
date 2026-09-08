<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class EventReport extends Model
{
    protected $fillable = ['event_id', 'reporter_user_id', 'category', 'details', 'status', 'reviewed_by_admin_id', 'reviewed_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    protected function casts(): array
    {
        return ['reviewed_at' => 'immutable_datetime'];
    }
}
