<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DiscoveryPreferenceLocation extends Model
{
    protected $fillable = ['country_code', 'city_name'];

    public function preference(): BelongsTo
    {
        return $this->belongsTo(DiscoveryPreference::class, 'discovery_preference_id');
    }
}
