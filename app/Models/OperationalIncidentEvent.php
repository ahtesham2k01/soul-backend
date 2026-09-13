<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class OperationalIncidentEvent extends Model
{
    public $timestamps = false;

    protected $fillable = ['operational_incident_id', 'type', 'severity', 'current_value', 'threshold', 'admin_user_id', 'reason', 'created_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $event) => $event->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['created_at' => 'immutable_datetime'];
    }

    public function incident(): BelongsTo { return $this->belongsTo(OperationalIncident::class, 'operational_incident_id'); }
    public function adminUser(): BelongsTo { return $this->belongsTo(User::class, 'admin_user_id'); }
}
