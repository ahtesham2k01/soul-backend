<?php

namespace App\Support\Entitlements;

use App\Models\Feature;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class EntitlementGate
{
    public function __construct(private readonly EntitlementResolver $resolver) {}

    public function consume(User $user, string $featureKey, ?string $platform = null): array
    {
        return DB::transaction(function () use ($user, $featureKey, $platform): array {
            $feature = Feature::where('key', $featureKey)->lockForUpdate()->first();
            $entitlement = $this->resolver->for($user, $platform)[$featureKey] ?? null;

            if (! $feature || ! $entitlement || ! $entitlement['enabled']) {
                return ['allowed' => false, 'reason' => 'FEATURE_UNAVAILABLE'];
            }

            if (($entitlement['daily_limit'] !== null && $entitlement['daily_used'] >= $entitlement['daily_limit'])
                || ($entitlement['monthly_limit'] !== null && $entitlement['monthly_used'] >= $entitlement['monthly_limit'])) {
                return ['allowed' => false, 'reason' => 'FEATURE_LIMIT_REACHED', 'entitlement' => $entitlement];
            }

            $identity = ['user_id' => $user->id, 'feature_id' => $feature->id, 'period_date' => now()->toDateString()];
            DB::table('feature_usage_counters')->insertOrIgnore([...$identity, 'count' => 0, 'created_at' => now(), 'updated_at' => now()]);
            DB::table('feature_usage_counters')->where($identity)->increment('count', 1, ['updated_at' => now()]);

            return ['allowed' => true, 'reason' => null, 'entitlement' => $this->resolver->for($user, $platform)[$featureKey]];
        });
    }
}
