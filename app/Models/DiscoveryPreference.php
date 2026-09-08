<?php

namespace App\Models;

use App\Enums\Profile\DiscoveryLocationMode;
use App\Enums\Profile\Gender;
use App\Enums\Profile\ReligionDiscoveryMode;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DiscoveryPreference extends Model
{
    protected $fillable = [
        'preferred_gender', 'minimum_age', 'maximum_age', 'same_country_only', 'religion_mode', 'location_mode', 'radius_km',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function locations(): HasMany
    {
        return $this->hasMany(DiscoveryPreferenceLocation::class);
    }

    public function intentions(): HasMany
    {
        return $this->hasMany(DiscoveryPreferenceIntention::class);
    }

    protected function casts(): array
    {
        return [
            'preferred_gender' => Gender::class,
            'minimum_age' => 'integer',
            'maximum_age' => 'integer',
            'same_country_only' => 'boolean',
            'religion_mode' => ReligionDiscoveryMode::class,
            'location_mode' => DiscoveryLocationMode::class,
            'radius_km' => 'integer',
        ];
    }
}
