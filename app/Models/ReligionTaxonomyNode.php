<?php

namespace App\Models;

use App\Enums\Profile\ReligionNodeType;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

#[Fillable([
    'parent_id',
    'type',
    'slug',
    'path',
    'is_active',
    'sort_order',
])]
#[Hidden([
    'id',
    'parent_id',
])]
class ReligionTaxonomyNode extends Model
{
    /**
     * Get the parent in the configured religion tree.
     *
     * @return BelongsTo<ReligionTaxonomyNode, $this>
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(
            self::class,
            'parent_id',
        );
    }

    /**
     * Get the next configured levels in the religion tree.
     *
     * @return HasMany<ReligionTaxonomyNode, $this>
     */
    public function children(): HasMany
    {
        return $this
            ->hasMany(self::class, 'parent_id')
            ->orderBy('sort_order')
            ->orderBy('id');
    }

    /**
     * Get every localized label configured for this node.
     *
     * @return HasMany<ReligionTaxonomyTranslation, $this>
     */
    public function translations(): HasMany
    {
        return $this->hasMany(
            ReligionTaxonomyTranslation::class,
            'node_id',
        );
    }

    /**
     * Get country-specific availability rules for this node.
     *
     * @return HasMany<ReligionTaxonomyCountry, $this>
     */
    public function countries(): HasMany
    {
        return $this->hasMany(
            ReligionTaxonomyCountry::class,
            'node_id',
        );
    }

    /**
     * Limit a query to nodes available globally or in the given country.
     * A node without country rows is globally available.
     *
     * @param Builder<ReligionTaxonomyNode> $query
     */
    public function scopeAvailableInCountry(
        Builder $query,
        string $countryCode,
    ): void {
        $countryCode = strtoupper($countryCode);

        $query->where(function (Builder $availability) use ($countryCode): void {
            $availability
                ->whereDoesntHave('countries')
                ->orWhereHas(
                    'countries',
                    fn (Builder $countries): Builder => $countries->where(
                        'country_code',
                        $countryCode,
                    ),
                );
        });
    }

    /**
     * Use public ULIDs for route model binding.
     */
    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    /**
     * Automatically generate the public catalog identifier.
     */
    protected static function booted(): void
    {
        static::creating(function (ReligionTaxonomyNode $node): void {
            if ($node->public_id === null) {
                $node->public_id = (string) Str::ulid();
            }
        });
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => ReligionNodeType::class,
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }
}
