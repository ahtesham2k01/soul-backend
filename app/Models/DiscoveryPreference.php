<?php

namespace App\Models;

use App\Enums\Profile\Gender;
use App\Enums\Profile\ReligionDiscoveryMode;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DiscoveryPreference extends Model
{
    protected $fillable = [
        'preferred_gender', 'minimum_age', 'maximum_age', 'same_country_only', 'religion_mode',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return [
            'preferred_gender' => Gender::class,
            'minimum_age' => 'integer',
            'maximum_age' => 'integer',
            'same_country_only' => 'boolean',
            'religion_mode' => ReligionDiscoveryMode::class,
        ];
    }
}
