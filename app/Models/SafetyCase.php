<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class SafetyCase extends Model
{
    protected $fillable = ['user_id', 'source_report_id', 'type', 'severity', 'status', 'reason', 'previous_profile_status', 'resolved_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $case) => $case->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['resolved_at' => 'immutable_datetime'];
    }
}
