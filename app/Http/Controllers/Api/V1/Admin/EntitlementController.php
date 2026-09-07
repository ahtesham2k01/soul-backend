<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Feature;
use App\Models\StoreProduct;
use App\Models\SubscriptionPlan;
use App\Models\SubscriptionPromotion;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\Entitlements\EntitlementResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\HttpException;

class EntitlementController extends Controller
{
    public function index(): JsonResponse
    {
        return ApiResponse::success(['features' => Feature::orderBy('key')->get()->map(fn ($x) => $x->only(['public_id', 'key', 'name', 'description', 'access_mode', 'is_enabled', 'daily_limit', 'monthly_limit', 'rollout_percentage', 'starts_at', 'ends_at'])), 'plans' => SubscriptionPlan::with('features')->orderBy('sort_order')->get()->map(fn ($x) => ['id' => $x->public_id, 'key' => $x->key, 'name' => $x->name, 'description' => $x->description, 'status' => $x->status, 'trial_days' => $x->trial_days, 'entitlements' => $x->features->map(fn ($f) => ['feature_id' => $f->public_id, 'key' => $f->key, 'is_enabled' => (bool) $f->pivot->is_enabled, 'daily_limit' => $f->pivot->daily_limit, 'monthly_limit' => $f->pivot->monthly_limit])]), 'products' => StoreProduct::with('plan:id,public_id,key')->get()->map(fn ($x) => ['id' => $x->public_id, 'plan_id' => $x->plan->public_id, 'plan_key' => $x->plan->key, 'platform' => $x->platform, 'product_id' => $x->product_id, 'country_code' => $x->country_code, 'is_active' => $x->is_active]), 'promotions' => SubscriptionPromotion::with('plan:id,public_id,key')->latest()->get()->map(fn ($x) => ['id' => $x->public_id, 'key' => $x->key, 'name' => $x->name, 'plan_id' => $x->plan->public_id, 'plan_key' => $x->plan->key, 'status' => $x->status, 'country_code' => $x->country_code, 'platform' => $x->platform, 'trial_days' => $x->trial_days, 'rollout_percentage' => $x->rollout_percentage, 'starts_at' => $x->starts_at, 'ends_at' => $x->ends_at])]);
    }

    public function storeFeature(Request $r): JsonResponse
    {
        $v = $r->validate(['key' => ['required', 'alpha_dash', 'max:80', 'unique:features,key'], 'name' => ['required', 'string', 'max:120'], 'description' => ['nullable', 'string', 'max:1000'], 'access_mode' => ['required', Rule::in(['universal', 'free', 'paid'])], 'is_enabled' => ['required', 'boolean'], 'daily_limit' => ['nullable', 'integer', 'min:1'], 'monthly_limit' => ['nullable', 'integer', 'min:1'], 'rollout_percentage' => ['required', 'integer', 'between:0,100'], 'starts_at' => ['nullable', 'date'], 'ends_at' => ['nullable', 'date', 'after:starts_at'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $this->guardSafety($v);
        $feature = Feature::create(collect($v)->except('reason')->all());
        $this->audit($r, $feature, 'feature.created', null, $feature->toArray(), $v['reason']);

        return ApiResponse::success(['feature' => $feature], 'Feature created.', 201);
    }

    public function updateFeature(Request $r, string $feature): JsonResponse
    {
        $record = Feature::where('public_id', $feature)->first();
        if (! $record) {
            return ApiResponse::error('FEATURE_NOT_FOUND', 'Feature not found.', 404);
        } $v = $r->validate(['name' => ['required', 'string', 'max:120'], 'description' => ['nullable', 'string', 'max:1000'], 'access_mode' => ['required', Rule::in(['universal', 'free', 'paid'])], 'is_enabled' => ['required', 'boolean'], 'daily_limit' => ['nullable', 'integer', 'min:1'], 'monthly_limit' => ['nullable', 'integer', 'min:1'], 'rollout_percentage' => ['required', 'integer', 'between:0,100'], 'starts_at' => ['nullable', 'date'], 'ends_at' => ['nullable', 'date', 'after:starts_at'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $this->guardSafety([...$v, 'key' => $record->key]);
        $before = $record->toArray();
        $record->update(collect($v)->except('reason')->all());
        $this->audit($r, $record, 'feature.updated', $before, $record->toArray(), $v['reason']);

        return ApiResponse::success(['feature' => $record]);
    }

    public function storePlan(Request $r): JsonResponse
    {
        $v = $r->validate(['key' => ['required', 'alpha_dash', 'max:80', 'unique:subscription_plans,key'], 'name' => ['required', 'string', 'max:120'], 'description' => ['nullable', 'string', 'max:1000'], 'status' => ['required', Rule::in(['draft', 'active', 'retired'])], 'trial_days' => ['required', 'integer', 'between:0,365'], 'sort_order' => ['sometimes', 'integer', 'min:0'], 'entitlements' => ['required', 'array'], 'entitlements.*.feature_id' => ['required', 'ulid', 'distinct'], 'entitlements.*.is_enabled' => ['required', 'boolean'], 'entitlements.*.daily_limit' => ['nullable', 'integer', 'min:1'], 'entitlements.*.monthly_limit' => ['nullable', 'integer', 'min:1'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $plan = DB::transaction(function () use ($r, $v) {
            $plan = SubscriptionPlan::create(collect($v)->except(['reason', 'entitlements'])->all());
            $this->sync($plan, $v['entitlements']);
            $this->audit($r, $plan, 'plan.created', null, $plan->toArray(), $v['reason']);

            return $plan;
        });

        return ApiResponse::success(['plan_id' => $plan->public_id], 'Plan created.', 201);
    }

    public function storeProduct(Request $r): JsonResponse
    {
        $v = $r->validate(['plan_id' => ['required', 'ulid'], 'platform' => ['required', Rule::in(['ios', 'android'])], 'product_id' => ['required', 'string', 'max:190'], 'country_code' => ['nullable', 'string', 'size:2'], 'is_active' => ['required', 'boolean'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $plan = SubscriptionPlan::where('public_id', $v['plan_id'])->first();
        if (! $plan) {
            return ApiResponse::error('PLAN_NOT_FOUND', 'Plan not found.', 404);
        }$product = StoreProduct::create(['subscription_plan_id' => $plan->id, 'platform' => $v['platform'], 'product_id' => $v['product_id'], 'country_code' => isset($v['country_code']) ? strtoupper($v['country_code']) : null, 'is_active' => $v['is_active']]);
        $this->audit($r, $product, 'store_product.created', null, $product->toArray(), $v['reason']);

        return ApiResponse::success(['product_id' => $product->public_id], 'Store product mapped.', 201);
    }

    public function override(Request $r, string $user): JsonResponse
    {
        $target = User::where('public_id', $user)->first();
        if (! $target) {
            return ApiResponse::error('USER_NOT_FOUND', 'User not found.', 404);
        }$v = $r->validate(['feature_id' => ['required', 'ulid'], 'is_enabled' => ['required', 'boolean'], 'daily_limit' => ['nullable', 'integer', 'min:1'], 'monthly_limit' => ['nullable', 'integer', 'min:1'], 'starts_at' => ['nullable', 'date'], 'ends_at' => ['nullable', 'date', 'after:starts_at'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $feature = Feature::where('public_id', $v['feature_id'])->first();
        if (! $feature) {
            return ApiResponse::error('FEATURE_NOT_FOUND', 'Feature not found.', 404);
        }if (in_array($feature->key, EntitlementResolver::NEVER_PAYWALLED, true) && ! $v['is_enabled']) {
            return ApiResponse::error('SAFETY_FEATURE_LOCKED', 'Safety/account capabilities cannot be disabled.', 409);
        }DB::table('user_entitlement_overrides')->updateOrInsert(['user_id' => $target->id, 'feature_id' => $feature->id], ['is_enabled' => $v['is_enabled'], 'daily_limit' => $v['daily_limit'] ?? null, 'monthly_limit' => $v['monthly_limit'] ?? null, 'starts_at' => $v['starts_at'] ?? null, 'ends_at' => $v['ends_at'] ?? null, 'created_at' => now(), 'updated_at' => now()]);
        $this->audit($r, $target, 'user_entitlement.updated', null, ['feature' => $feature->key, 'enabled' => $v['is_enabled']], $v['reason']);

        return ApiResponse::success(['updated' => true]);
    }

    public function countryOverride(Request $r, string $feature): JsonResponse
    {
        $record = Feature::where('public_id', $feature)->first();
        if (! $record) {
            return ApiResponse::error('FEATURE_NOT_FOUND', 'Feature not found.', 404);
        }$v = $r->validate(['country_code' => ['required', 'string', 'size:2'], 'is_enabled' => ['required', 'boolean'], 'daily_limit' => ['nullable', 'integer', 'min:1'], 'monthly_limit' => ['nullable', 'integer', 'min:1'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        if (in_array($record->key, EntitlementResolver::NEVER_PAYWALLED, true) && ! $v['is_enabled']) {
            return ApiResponse::error('SAFETY_FEATURE_LOCKED', 'Safety/account capabilities cannot be disabled.', 409);
        }$country = strtoupper($v['country_code']);
        DB::table('country_feature_overrides')->updateOrInsert(['feature_id' => $record->id, 'country_code' => $country], ['is_enabled' => $v['is_enabled'], 'daily_limit' => $v['daily_limit'] ?? null, 'monthly_limit' => $v['monthly_limit'] ?? null, 'created_at' => now(), 'updated_at' => now()]);
        $this->audit($r, $record, 'country_entitlement.updated', null, ['country_code' => $country, 'enabled' => $v['is_enabled']], $v['reason']);

        return ApiResponse::success(['updated' => true]);
    }

    public function platformOverride(Request $r, string $feature): JsonResponse
    {
        $record = Feature::where('public_id', $feature)->first();
        if (! $record) {
            return ApiResponse::error('FEATURE_NOT_FOUND', 'Feature not found.', 404);
        }$v = $r->validate(['platform' => ['required', Rule::in(['ios', 'android'])], 'is_enabled' => ['required', 'boolean'], 'daily_limit' => ['nullable', 'integer', 'min:1'], 'monthly_limit' => ['nullable', 'integer', 'min:1'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        if (in_array($record->key, EntitlementResolver::NEVER_PAYWALLED, true) && ! $v['is_enabled']) {
            return ApiResponse::error('SAFETY_FEATURE_LOCKED', 'Safety/account capabilities cannot be disabled.', 409);
        }DB::table('platform_feature_overrides')->updateOrInsert(['feature_id' => $record->id, 'platform' => $v['platform']], ['is_enabled' => $v['is_enabled'], 'daily_limit' => $v['daily_limit'] ?? null, 'monthly_limit' => $v['monthly_limit'] ?? null, 'created_at' => now(), 'updated_at' => now()]);
        $this->audit($r, $record, 'platform_entitlement.updated', null, ['platform' => $v['platform'], 'enabled' => $v['is_enabled']], $v['reason']);

        return ApiResponse::success(['updated' => true]);
    }

    public function storePromotion(Request $r): JsonResponse
    {
        $v = $r->validate(['key' => ['required', 'alpha_dash', 'max:80', 'unique:subscription_promotions,key'], 'name' => ['required', 'string', 'max:120'], 'plan_id' => ['required', 'ulid'], 'status' => ['required', Rule::in(['draft', 'active', 'retired'])], 'country_code' => ['nullable', 'string', 'size:2'], 'platform' => ['nullable', Rule::in(['ios', 'android'])], 'trial_days' => ['required', 'integer', 'between:0,365'], 'rollout_percentage' => ['required', 'integer', 'between:0,100'], 'starts_at' => ['required', 'date'], 'ends_at' => ['required', 'date', 'after:starts_at'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $plan = SubscriptionPlan::where('public_id', $v['plan_id'])->first();
        if (! $plan) {
            return ApiResponse::error('PLAN_NOT_FOUND', 'Plan not found.', 404);
        }$promotion = SubscriptionPromotion::create(['key' => $v['key'], 'name' => $v['name'], 'subscription_plan_id' => $plan->id, 'status' => $v['status'], 'country_code' => isset($v['country_code']) ? strtoupper($v['country_code']) : null, 'platform' => $v['platform'] ?? null, 'trial_days' => $v['trial_days'], 'rollout_percentage' => $v['rollout_percentage'], 'starts_at' => $v['starts_at'], 'ends_at' => $v['ends_at']]);
        $this->audit($r, $promotion, 'promotion.created', null, $promotion->toArray(), $v['reason']);

        return ApiResponse::success(['promotion_id' => $promotion->public_id], 'Promotion created.', 201);
    }

    private function sync(SubscriptionPlan $plan, array $items): void
    {
        foreach ($items as $item) {
            $feature = Feature::where('public_id', $item['feature_id'])->firstOrFail();
            $plan->features()->attach($feature->id, ['is_enabled' => $item['is_enabled'], 'daily_limit' => $item['daily_limit'] ?? null, 'monthly_limit' => $item['monthly_limit'] ?? null]);
        }
    }

    private function guardSafety(array $v): void
    {
        if (in_array($v['key'], EntitlementResolver::NEVER_PAYWALLED, true) && (! $v['is_enabled'] || $v['access_mode'] === 'paid' || isset($v['daily_limit']) || isset($v['monthly_limit']))) {
            throw new HttpException(409, 'Safety/account capabilities must remain universally available.');
        }
    }

    private function audit(Request $r,$subject,string $action,?array $before,array $after,string $reason): void
    {
        AdminAuditLog::create(['admin_user_id' => $r->user()->id, 'action' => $action, 'subject_type' => $subject::class, 'subject_id' => $subject->id, 'before' => $before, 'after' => $after, 'reason' => $reason, 'ip_address' => $r->ip()]);
    }
}
