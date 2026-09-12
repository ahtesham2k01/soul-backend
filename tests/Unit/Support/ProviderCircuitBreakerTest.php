<?php

namespace Tests\Unit\Support;

use App\Support\Providers\ProviderCircuitBreaker;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class ProviderCircuitBreakerTest extends TestCase
{
    public function test_it_opens_after_threshold_and_success_resets_it(): void
    {
        Cache::flush();
        config()->set('soul.providers.circuit_breaker.failure_threshold', 2);
        $breaker = app(ProviderCircuitBreaker::class);

        $breaker->recordTransientFailure('push:fcm');
        $this->assertFalse($breaker->isOpen('push:fcm'));
        $breaker->recordTransientFailure('push:fcm');
        $this->assertTrue($breaker->isOpen('push:fcm'));
        $this->assertSame('open', $breaker->states(['push:fcm'])['push:fcm']['state']);

        $breaker->recordSuccess('push:fcm');
        $this->assertFalse($breaker->isOpen('push:fcm'));
        $this->assertSame(0, $breaker->states(['push:fcm'])['push:fcm']['transient_failures']);
    }

    public function test_provider_keys_are_isolated(): void
    {
        Cache::flush();
        config()->set('soul.providers.circuit_breaker.failure_threshold', 1);
        $breaker = app(ProviderCircuitBreaker::class);
        $breaker->recordTransientFailure('store:ios');

        $this->assertTrue($breaker->isOpen('store:ios'));
        $this->assertFalse($breaker->isOpen('store:android'));
    }

    public function test_only_one_half_open_probe_is_allowed_after_cooldown(): void
    {
        Cache::flush();
        config()->set('soul.providers.circuit_breaker.failure_threshold', 1);
        config()->set('soul.providers.circuit_breaker.cooldown_seconds', 1);
        $breaker = app(ProviderCircuitBreaker::class);
        $breaker->recordTransientFailure('store:android');
        $this->travel(2)->seconds();

        $this->assertTrue($breaker->allowsRequest('store:android'));
        $this->assertFalse($breaker->allowsRequest('store:android'));
        $this->assertSame('half_open', $breaker->states(['store:android'])['store:android']['state']);
    }
}
