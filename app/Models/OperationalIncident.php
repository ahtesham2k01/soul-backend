<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class OperationalIncident extends Model
{
    protected $fillable = ['fingerprint', 'code', 'severity', 'status', 'current_value', 'threshold', 'first_detected_at', 'last_detected_at', 'acknowledged_by_admin_id', 'acknowledged_at', 'resolved_by_admin_id', 'resolved_at', 'resolution_reason'];

    protected static function booted(): void
    {
        static::creating(fn (self $incident) => $incident->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['first_detected_at' => 'immutable_datetime', 'last_detected_at' => 'immutable_datetime', 'acknowledged_at' => 'immutable_datetime', 'resolved_at' => 'immutable_datetime'];
    }

    public function acknowledgedBy(): BelongsTo { return $this->belongsTo(User::class, 'acknowledged_by_admin_id'); }
    public function resolvedBy(): BelongsTo { return $this->belongsTo(User::class, 'resolved_by_admin_id'); }
}
