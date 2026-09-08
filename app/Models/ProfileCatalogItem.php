<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class ProfileCatalogItem extends Model
{
    protected $fillable = ['type', 'key', 'is_active', 'sort_order', 'updated_by_admin_id'];

    protected static function booted(): void
    {
        static::creating(fn (self $item) => $item->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'sort_order' => 'integer'];
    }

    public function translations(): HasMany
    {
        return $this->hasMany(ProfileCatalogTranslation::class);
    }
}
