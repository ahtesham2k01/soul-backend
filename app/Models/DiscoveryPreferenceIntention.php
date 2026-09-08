<?php

namespace App\Models;

use App\Enums\Profile\RelationshipIntention;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DiscoveryPreferenceIntention extends Model
{
    protected $fillable = ['intention'];

    public function preference(): BelongsTo
    {
        return $this->belongsTo(DiscoveryPreference::class, 'discovery_preference_id');
    }

    protected function casts(): array
    {
        return ['intention' => RelationshipIntention::class];
    }
}
