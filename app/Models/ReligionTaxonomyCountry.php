<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'country_code',
])]
#[Hidden([
    'id',
    'node_id',
])]
class ReligionTaxonomyCountry extends Model
{
    /**
     * Get the taxonomy node restricted to this country.
     *
     * @return BelongsTo<ReligionTaxonomyNode, $this>
     */
    public function node(): BelongsTo
    {
        return $this->belongsTo(
            ReligionTaxonomyNode::class,
            'node_id',
        );
    }

    /**
     * Normalize ISO country codes before saving them.
     */
    protected static function booted(): void
    {
        static::saving(function (ReligionTaxonomyCountry $country): void {
            $country->country_code = strtoupper($country->country_code);
        });
    }
}
