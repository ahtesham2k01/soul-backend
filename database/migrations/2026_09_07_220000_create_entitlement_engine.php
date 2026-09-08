<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('features', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('key', 80)->unique();
            $table->string('name', 120);
            $table->text('description')->nullable();
            $table->string('access_mode', 20)->default('universal');
            $table->boolean('is_enabled')->default(true);
            $table->unsignedInteger('daily_limit')->nullable();
            $table->unsignedInteger('monthly_limit')->nullable();
            $table->unsignedTinyInteger('rollout_percentage')->default(100);
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();
        });
        Schema::create('subscription_plans', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('key', 80)->unique();
            $table->string('name', 120);
            $table->text('description')->nullable();
            $table->string('status', 20)->default('draft');
            $table->unsignedSmallInteger('trial_days')->default(0);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });
        Schema::create('plan_entitlements', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('subscription_plan_id')->constrained()->cascadeOnDelete();
            $table->foreignId('feature_id')->constrained()->cascadeOnDelete();
            $table->boolean('is_enabled')->default(true);
            $table->unsignedInteger('daily_limit')->nullable();
            $table->unsignedInteger('monthly_limit')->nullable();
            $table->unique(['subscription_plan_id', 'feature_id']);
        });
        Schema::create('store_products', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('subscription_plan_id')->constrained()->cascadeOnDelete();
            $table->string('platform', 20);
            $table->string('product_id', 190);
            $table->char('country_code', 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['platform', 'product_id', 'country_code']);
        });
        Schema::create('user_subscriptions', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_plan_id')->constrained()->restrictOnDelete();
            $table->string('platform', 20);
            $table->string('provider_transaction_id', 190);
            $table->string('status', 20);
            $table->timestamp('starts_at');
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
            $table->unique(['platform', 'provider_transaction_id']);
            $table->index(['user_id', 'status', 'expires_at']);
        });
        Schema::create('subscription_promotions', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('key', 80)->unique();
            $table->string('name', 120);
            $table->foreignId('subscription_plan_id')->constrained()->cascadeOnDelete();
            $table->string('status', 20)->default('draft');
            $table->char('country_code', 2)->nullable();
            $table->string('platform', 20)->nullable();
            $table->unsignedSmallInteger('trial_days')->default(0);
            $table->unsignedTinyInteger('rollout_percentage')->default(100);
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->timestamps();
            $table->index(['status', 'starts_at', 'ends_at']);
        });
        Schema::create('user_entitlement_overrides', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('feature_id')->constrained()->cascadeOnDelete();
            $table->boolean('is_enabled');
            $table->unsignedInteger('daily_limit')->nullable();
            $table->unsignedInteger('monthly_limit')->nullable();
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'feature_id']);
        });
        Schema::create('country_feature_overrides', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('feature_id')->constrained()->cascadeOnDelete();
            $table->char('country_code', 2);
            $table->boolean('is_enabled');
            $table->unsignedInteger('daily_limit')->nullable();
            $table->unsignedInteger('monthly_limit')->nullable();
            $table->timestamps();
            $table->unique(['feature_id', 'country_code']);
        });
        Schema::create('platform_feature_overrides', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('feature_id')->constrained()->cascadeOnDelete();
            $table->string('platform', 20);
            $table->boolean('is_enabled');
            $table->unsignedInteger('daily_limit')->nullable();
            $table->unsignedInteger('monthly_limit')->nullable();
            $table->timestamps();
            $table->unique(['feature_id', 'platform']);
        });
        Schema::create('feature_usage_counters', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('feature_id')->constrained()->cascadeOnDelete();
            $table->date('period_date');
            $table->unsignedInteger('count')->default(0);
            $table->timestamps();
            $table->unique(['user_id', 'feature_id', 'period_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('feature_usage_counters');
        Schema::dropIfExists('platform_feature_overrides');
        Schema::dropIfExists('country_feature_overrides');
        Schema::dropIfExists('user_entitlement_overrides');
        Schema::dropIfExists('subscription_promotions');
        Schema::dropIfExists('user_subscriptions');
        Schema::dropIfExists('store_products');
        Schema::dropIfExists('plan_entitlements');
        Schema::dropIfExists('subscription_plans');
        Schema::dropIfExists('features');
    }
};
