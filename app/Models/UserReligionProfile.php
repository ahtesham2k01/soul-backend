<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'selected_node_id',
    'country_code',
])]
#[Hidden([
    'id',
    'user_id',
    'selected_node_id',
])]
class UserReligionProfile extends Model
{
    use HasFactory;

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsTo<ReligionTaxonomyNode, $this> */
    public function selectedNode(): BelongsTo
    {
        return $this->belongsTo(
            ReligionTaxonomyNode::class,
            'selected_node_id',
        );
    }
}
