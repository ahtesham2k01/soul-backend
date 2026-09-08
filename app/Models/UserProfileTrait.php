<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfileTrait extends Model
{
    protected $fillable = ['value', 'profile_catalog_item_id'];

    public function userProfile(): BelongsTo
    {
        return $this->belongsTo(UserProfile::class);
    }

    public function catalogItem(): BelongsTo
    {
        return $this->belongsTo(ProfileCatalogItem::class, 'profile_catalog_item_id');
    }
}
