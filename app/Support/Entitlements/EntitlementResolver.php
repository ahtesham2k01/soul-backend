<?php

namespace App\Support\Entitlements;

use App\Models\Feature;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class EntitlementResolver
{
    public const NEVER_PAYWALLED = ['block', 'report', 'account_deletion', 'core_privacy', 'safety_appeal', 'safety_support'];

    public function for(User $user, ?string $platform = null): array
    {
        $planId = DB::table('user_subscriptions')->where('user_id', $user->id)->where('status', 'active')->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()))->latest('id')->value('subscription_plan_id');
        $country = $user->profile?->country_code;

        return Feature::query()->orderBy('key')->get()->mapWithKeys(function (Feature $feature) use ($user, $planId, $country, $platform): array {
            $enabled = $feature->is_enabled && (! $feature->starts_at || $feature->starts_at->isPast()) && (! $feature->ends_at || $feature->ends_at->isFuture());
            $daily = $feature->daily_limit;
            $monthly = $feature->monthly_limit;
            $source = 'feature';
            if ($feature->access_mode === 'paid') {
                $enabled = false;
            }
            if ($planId && ($plan = DB::table('plan_entitlements')->where('subscription_plan_id', $planId)->where('feature_id', $feature->id)->first())) {
                $enabled = (bool) $plan->is_enabled;
                $daily = $plan->daily_limit ?? $daily;
                $monthly = $plan->monthly_limit ?? $monthly;
                $source = 'plan';
            }
            if ($country && ($override = DB::table('country_feature_overrides')->where('feature_id', $feature->id)->where('country_code', $country)->first())) {
                $enabled = (bool) $override->is_enabled;
                $daily = $override->daily_limit ?? $daily;
                $monthly = $override->monthly_limit ?? $monthly;
                $source = 'country';
            }
            if ($platform && ($override = DB::table('platform_feature_overrides')->where('feature_id', $feature->id)->where('platform', $platform)->first())) {
                $enabled = (bool) $override->is_enabled;
                $daily = $override->daily_limit ?? $daily;
                $monthly = $override->monthly_limit ?? $monthly;
                $source = 'platform';
            }
            if ($override = DB::table('user_entitlement_overrides')->where('feature_id', $feature->id)->where('user_id', $user->id)->where(fn ($q) => $q->whereNull('starts_at')->orWhere('starts_at', '<=', now()))->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>', now()))->first()) {
                $enabled = (bool) $override->is_enabled;
                $daily = $override->daily_limit ?? $daily;
                $monthly = $override->monthly_limit ?? $monthly;
                $source = 'user';
            }
            if ($feature->rollout_percentage < 100) {
                $enabled = $enabled && (hexdec(substr(hash('sha256', $user->public_id.'|'.$feature->key), 0, 8)) % 100) < $feature->rollout_percentage;
            }
            if (in_array($feature->key, self::NEVER_PAYWALLED, true)) {
                $enabled = true;
                $daily = null;
                $monthly = null;
                $source = 'safety_invariant';
            }
            $today = DB::table('feature_usage_counters')->where('user_id', $user->id)->where('feature_id', $feature->id)->where('period_date', now()->toDateString())->value('count') ?? 0;
            $month = DB::table('feature_usage_counters')->where('user_id', $user->id)->where('feature_id', $feature->id)->whereBetween('period_date', [now()->startOfMonth()->toDateString(), now()->endOfMonth()->toDateString()])->sum('count');

            return [$feature->key => ['enabled' => $enabled, 'daily_limit' => $daily, 'daily_used' => (int) $today, 'monthly_limit' => $monthly, 'monthly_used' => (int) $month, 'source' => $source]];
        })->all();
    }
}
