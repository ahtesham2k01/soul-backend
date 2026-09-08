<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class StoreProduct extends Model
{
    protected $fillable = ['subscription_plan_id', 'platform', 'product_id', 'country_code', 'is_active'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }
}
