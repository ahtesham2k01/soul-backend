<?php

namespace App\Models;

use Database\Factories\SpokenLanguageFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class SpokenLanguage extends Model
{
    /** @use HasFactory<SpokenLanguageFactory> */
    use HasFactory;

    protected $fillable = [
        'code',
        'name',
        'native_name',
        'is_active',
        'sort_order',
    ];

    /** @return BelongsToMany<UserProfile, $this> */
    public function userProfiles(): BelongsToMany
    {
        return $this->belongsToMany(UserProfile::class)
            ->withTimestamps();
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }
}
