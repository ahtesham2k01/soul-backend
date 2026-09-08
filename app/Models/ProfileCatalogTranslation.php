<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProfileCatalogTranslation extends Model
{
    protected $fillable = ['locale', 'label'];

    public function item(): BelongsTo
    {
        return $this->belongsTo(ProfileCatalogItem::class, 'profile_catalog_item_id');
    }
}
