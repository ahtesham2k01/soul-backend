<?php

namespace Tests\Feature\Api\V1\Subscriptions;

use App\Contracts\Billing\StorePurchaseVerifier;
use App\Jobs\ProcessStoreWebhook;
use App\Models\StoreProduct;
use App\Models\SubscriptionPlan;
use App\Models\User;
use App\Support\Billing\VerifiedStorePurchase;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PurchaseLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_verified_purchase_activates_dynamic_plan_without_returning_receipt(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $plan = SubscriptionPlan::create(['key' => 'premium', 'name' => 'Premium', 'status' => 'active', 'trial_days' => 3]);
        StoreProduct::create(['subscription_plan_id' => $plan->id, 'platform' => 'android', 'product_id' => 'soul.premium.monthly', 'is_active' => true]);
        $this->app->instance(StorePurchaseVerifier::class, new class implements StorePurchaseVerifier {
            public function verify(string $platform, string $productId, string $receipt): VerifiedStorePurchase { return new VerifiedStorePurchase($productId, 'transaction-1', 'original-1', 'active', CarbonImmutable::now(), CarbonImmutable::now()->addMonth()); }
            public function verifyWebhook(string $platform, string $payload): array { return []; }
        });
        Sanctum::actingAs($user);
        $this->postJson('/api/v1/subscription/purchases', ['platform' => 'android', 'product_id' => 'soul.premium.monthly', 'receipt' => 'private-purchase-token'])
            ->assertOk()->assertJsonPath('data.purchase.status', 'active')->assertJsonMissing(['receipt' => 'private-purchase-token']);
        $this->assertDatabaseHas('user_subscriptions', ['user_id' => $user->id, 'subscription_plan_id' => $plan->id, 'status' => 'active']);
    }

    public function test_same_receipt_cannot_be_claimed_by_another_member(): void
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]); $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $plan = SubscriptionPlan::create(['key' => 'plus', 'name' => 'Plus', 'status' => 'active']);
        StoreProduct::create(['subscription_plan_id' => $plan->id, 'platform' => 'ios', 'product_id' => 'soul.plus.weekly', 'is_active' => true]);
        $this->app->instance(StorePurchaseVerifier::class, new class implements StorePurchaseVerifier {
            public function verify(string $platform, string $productId, string $receipt): VerifiedStorePurchase { return new VerifiedStorePurchase($productId, 'tx-unique', null, 'active', CarbonImmutable::now(), null); }
            public function verifyWebhook(string $platform, string $payload): array { return []; }
        });
        Sanctum::actingAs($first); $payload = ['platform' => 'ios', 'product_id' => 'soul.plus.weekly', 'receipt' => 'one-receipt'];
        $this->postJson('/api/v1/subscription/purchases', $payload)->assertOk();
        Sanctum::actingAs($second); $this->postJson('/api/v1/subscription/purchases', $payload)->assertStatus(409)->assertJsonPath('error.code', 'PURCHASE_ALREADY_CLAIMED');
    }

    public function test_store_webhook_is_deduplicated_before_queueing(): void
    {
        Queue::fake(); $payload = ['signedPayload' => 'provider-signed-value'];
        $this->postJson('/api/v1/webhooks/stores/ios', $payload)->assertStatus(202);
        $this->postJson('/api/v1/webhooks/stores/ios', $payload)->assertStatus(202);
        $this->assertDatabaseCount('store_webhook_events', 1);
        Queue::assertPushed(ProcessStoreWebhook::class, 1);
    }
}
