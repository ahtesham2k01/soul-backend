<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class SubscriptionPromotion extends Model
{
    protected $fillable = ['key', 'name', 'subscription_plan_id', 'status', 'country_code', 'platform', 'trial_days', 'rollout_percentage', 'starts_at', 'ends_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $promotion) => $promotion->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['starts_at' => 'immutable_datetime', 'ends_at' => 'immutable_datetime'];
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }
}
