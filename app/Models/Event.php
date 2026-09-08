<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Event extends Model
{
    protected $fillable = ['created_by_admin_id', 'type', 'status', 'starts_at', 'ends_at', 'timezone', 'city', 'country_code', 'online_url', 'capacity', 'registration_count', 'published_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $event) => $event->public_id ??= (string) Str::ulid());
    }

    public function translations(): HasMany
    {
        return $this->hasMany(EventTranslation::class);
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(EventRegistration::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(EventReport::class);
    }

    protected function casts(): array
    {
        return ['starts_at' => 'immutable_datetime', 'ends_at' => 'immutable_datetime', 'published_at' => 'immutable_datetime'];
    }
}
