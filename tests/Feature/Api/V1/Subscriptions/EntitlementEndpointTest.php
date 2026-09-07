<?php

namespace Tests\Feature\Api\V1\Subscriptions;

use App\Models\Feature;
use App\Models\StoreProduct;
use App\Models\SubscriptionPlan;
use App\Models\User;
use App\Support\Entitlements\EntitlementGate;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EntitlementEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_effective_entitlements_apply_plan_country_platform_and_user_precedence(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $feature = Feature::create(['key' => 'advanced_filters', 'name' => 'Advanced filters', 'access_mode' => 'paid', 'is_enabled' => true, 'daily_limit' => 2]);
        $plan = SubscriptionPlan::create(['key' => 'plus', 'name' => 'Plus', 'status' => 'active']);
        $plan->features()->attach($feature, ['is_enabled' => true, 'daily_limit' => 5]);
        DB::table('user_subscriptions')->insert(['public_id' => (string) Str::ulid(), 'user_id' => $user->id, 'subscription_plan_id' => $plan->id, 'platform' => 'ios', 'provider_transaction_id' => 'tx-test', 'status' => 'active', 'starts_at' => now(), 'created_at' => now(), 'updated_at' => now()]);
        DB::table('platform_feature_overrides')->insert(['feature_id' => $feature->id, 'platform' => 'ios', 'is_enabled' => true, 'daily_limit' => 4, 'created_at' => now(), 'updated_at' => now()]);
        DB::table('user_entitlement_overrides')->insert(['user_id' => $user->id, 'feature_id' => $feature->id, 'is_enabled' => true, 'daily_limit' => 3, 'created_at' => now(), 'updated_at' => now()]);

        Sanctum::actingAs($user);
        $this->getJson('/api/v1/subscription/entitlements?platform=ios')->assertOk()
            ->assertJsonPath('data.capabilities.advanced_filters.enabled', true)
            ->assertJsonPath('data.capabilities.advanced_filters.daily_limit', 3)
            ->assertJsonPath('data.capabilities.advanced_filters.source', 'user');
    }

    public function test_gate_enforces_limit_and_safety_features_remain_unlimited(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Feature::create(['key' => 'boost', 'name' => 'Boost', 'access_mode' => 'universal', 'is_enabled' => true, 'daily_limit' => 1]);
        Feature::create(['key' => 'report', 'name' => 'Report', 'access_mode' => 'paid', 'is_enabled' => false, 'daily_limit' => 1]);
        $gate = app(EntitlementGate::class);

        $this->assertTrue($gate->consume($user, 'boost')['allowed']);
        $this->assertSame('FEATURE_LIMIT_REACHED', $gate->consume($user, 'boost')['reason']);
        $safety = $gate->consume($user, 'report');
        $this->assertTrue($safety['allowed']);
        $this->assertNull($safety['entitlement']['daily_limit']);
    }

    public function test_member_receives_only_active_products_for_platform_and_country(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $plan = SubscriptionPlan::create(['key' => 'plus', 'name' => 'Plus', 'status' => 'active']);
        StoreProduct::create(['subscription_plan_id' => $plan->id, 'platform' => 'android', 'product_id' => 'soul.plus.pk', 'country_code' => 'PK', 'is_active' => true]);
        StoreProduct::create(['subscription_plan_id' => $plan->id, 'platform' => 'ios', 'product_id' => 'soul.plus.ios', 'is_active' => true]);

        Sanctum::actingAs($user);
        $this->getJson('/api/v1/subscription/products?platform=android&country_code=PK')->assertOk()
            ->assertJsonCount(1, 'data.products')->assertJsonPath('data.products.0.product_id', 'soul.plus.pk');
    }

    public function test_only_super_admin_can_manage_entitlements_and_safety_cannot_be_paywalled(): void
    {
        $moderator = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'moderator']);
        Sanctum::actingAs($moderator);
        $this->getJson('/api/v1/admin/entitlements')->assertForbidden();

        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        Sanctum::actingAs($admin);
        $this->postJson('/api/v1/admin/entitlements/features', ['key' => 'report', 'name' => 'Report', 'access_mode' => 'paid', 'is_enabled' => true, 'rollout_percentage' => 100, 'reason' => 'Configure safety capability'])->assertStatus(409);
        $this->postJson('/api/v1/admin/entitlements/features', ['key' => 'boost', 'name' => 'Boost', 'access_mode' => 'paid', 'is_enabled' => true, 'daily_limit' => 1, 'rollout_percentage' => 100, 'reason' => 'Prepare launch catalog'])->assertCreated();
        $this->assertDatabaseHas('admin_audit_logs', ['action' => 'feature.created']);
    }

    public function test_super_admin_can_configure_complete_launch_catalog_without_prices(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        Sanctum::actingAs($admin);
        $featureId = $this->postJson('/api/v1/admin/entitlements/features', ['key' => 'boost', 'name' => 'Boost', 'access_mode' => 'paid', 'is_enabled' => true, 'rollout_percentage' => 50, 'reason' => 'Prepare controlled launch'])->assertCreated()->json('data.feature.public_id');
        $planId = $this->postJson('/api/v1/admin/entitlements/plans', ['key' => 'launch_plus', 'name' => 'Launch Plus', 'status' => 'active', 'trial_days' => 7, 'entitlements' => [['feature_id' => $featureId, 'is_enabled' => true, 'daily_limit' => 2]], 'reason' => 'Prepare launch plan'])->assertCreated()->json('data.plan_id');
        $productId = $this->postJson('/api/v1/admin/entitlements/products', ['plan_id' => $planId, 'platform' => 'ios', 'product_id' => 'com.soul.launch.plus', 'country_code' => 'pk', 'is_active' => true, 'reason' => 'Map approved store product'])->assertCreated()->json('data.product_id');
        $promotionId = $this->postJson('/api/v1/admin/entitlements/promotions', ['key' => 'launch_trial', 'name' => 'Launch trial', 'plan_id' => $planId, 'status' => 'active', 'country_code' => 'pk', 'platform' => 'ios', 'trial_days' => 14, 'rollout_percentage' => 25, 'starts_at' => now()->addDay()->toIso8601String(), 'ends_at' => now()->addMonth()->toIso8601String(), 'reason' => 'Schedule measured launch'])->assertCreated()->json('data.promotion_id');
        $this->putJson("/api/v1/admin/entitlements/features/{$featureId}/countries", ['country_code' => 'pk', 'is_enabled' => true, 'daily_limit' => 1, 'reason' => 'Set country allocation'])->assertOk();
        $this->putJson("/api/v1/admin/entitlements/features/{$featureId}/platforms", ['platform' => 'ios', 'is_enabled' => true, 'reason' => 'Enable iOS launch'])->assertOk();
        $this->putJson("/api/v1/admin/entitlements/plans/{$planId}", ['name' => 'Launch Plus Updated', 'description' => null, 'status' => 'retired', 'trial_days' => 0, 'sort_order' => 2, 'entitlements' => [['feature_id' => $featureId, 'is_enabled' => true, 'daily_limit' => 1]], 'reason' => 'Retire tested launch plan'])->assertOk();
        $this->putJson("/api/v1/admin/entitlements/products/{$productId}", ['is_active' => false, 'reason' => 'Deactivate retired product'])->assertOk()->assertJsonPath('data.is_active', false);
        $this->putJson("/api/v1/admin/entitlements/promotions/{$promotionId}", ['status' => 'retired', 'reason' => 'Retire completed promotion'])->assertOk()->assertJsonPath('data.status', 'retired');

        $this->getJson('/api/v1/admin/entitlements')->assertOk()
            ->assertJsonPath('data.plans.0.key', 'launch_plus')
            ->assertJsonPath('data.products.0.product_id', 'com.soul.launch.plus')
            ->assertJsonPath('data.promotions.0.key', 'launch_trial')
            ->assertJsonMissing(['price' => 1]);
        $this->assertDatabaseCount('admin_audit_logs', 9);
    }
}
