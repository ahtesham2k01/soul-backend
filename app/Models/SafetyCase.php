<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class SafetyCase extends Model
{
    protected $fillable = [
        'user_id',
        'source_report_id',
        'type',
        'signal_key',
        'severity',
        'status',
        'reason',
        'evidence',
        'occurrence_count',
        'first_observed_at',
        'last_observed_at',
        'previous_profile_status',
        'resolved_at',
    ];

    protected static function booted(): void
    {
        static::creating(fn (self $case) => $case->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return [
            'evidence' => 'array',
            'occurrence_count' => 'integer',
            'first_observed_at' => 'immutable_datetime',
            'last_observed_at' => 'immutable_datetime',
            'resolved_at' => 'immutable_datetime',
        ];
    }
}
