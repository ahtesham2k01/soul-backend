<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Str;

class SubscriptionPlan extends Model
{
    protected $fillable = ['key', 'name', 'description', 'status', 'trial_days', 'sort_order'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
    }

    public function features(): BelongsToMany
    {
        return $this->belongsToMany(Feature::class, 'plan_entitlements')->withPivot(['is_enabled', 'daily_limit', 'monthly_limit']);
    }
}
