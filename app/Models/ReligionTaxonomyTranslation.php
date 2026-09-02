<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'locale',
    'label',
    'description',
])]
#[Hidden([
    'id',
    'node_id',
])]
class ReligionTaxonomyTranslation extends Model
{
    /**
     * Get the taxonomy node owning this translation.
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
}
