<?php

namespace App\Support\Providers;

use Illuminate\Support\Facades\Cache;

class ProviderCircuitBreaker
{
    public function isOpen(string $provider): bool
    {
        return (int) Cache::get($this->openKey($provider), 0) > now()->timestamp;
    }

    public function allowsRequest(string $provider): bool
    {
        $until = (int) Cache::get($this->openKey($provider), 0);
        if ($until === 0) return true;
        if ($until > now()->timestamp) return false;

        return Cache::add(
            $this->probeKey($provider),
            true,
            max(1, (int) config('soul.providers.circuit_breaker.probe_lease_seconds', 15)),
        );
    }

    public function recordSuccess(string $provider): void
    {
        Cache::forget($this->failureKey($provider));
        Cache::forget($this->openKey($provider));
        Cache::forget($this->probeKey($provider));
    }

    public function recordTransientFailure(string $provider): void
    {
        Cache::forget($this->probeKey($provider));
        $window = max(1, (int) config('soul.providers.circuit_breaker.failure_window_seconds', 60));
        Cache::add($this->failureKey($provider), 0, $window);
        $failures = (int) Cache::increment($this->failureKey($provider));
        if ($failures >= max(1, (int) config('soul.providers.circuit_breaker.failure_threshold', 5))) {
            Cache::put($this->openKey($provider), now()->addSeconds(max(1, (int) config('soul.providers.circuit_breaker.cooldown_seconds', 60)))->timestamp);
        }
    }

    /** @param array<int,string> $providers */
    public function states(array $providers): array
    {
        return collect($providers)->mapWithKeys(function (string $provider): array {
            $until = (int) Cache::get($this->openKey($provider), 0);
            return [$provider => [
                'state' => $until > now()->timestamp ? 'open' : ($until > 0 ? 'half_open' : 'closed'),
                'transient_failures' => (int) Cache::get($this->failureKey($provider), 0),
                'retry_after_seconds' => max(0, $until - now()->timestamp),
            ]];
        })->all();
    }

    private function failureKey(string $provider): string
    {
        return 'provider-circuit:'.hash('sha256', $provider).':failures';
    }

    private function openKey(string $provider): string
    {
        return 'provider-circuit:'.hash('sha256', $provider).':open-until';
    }

    private function probeKey(string $provider): string
    {
        return 'provider-circuit:'.hash('sha256', $provider).':probe';
    }
}
