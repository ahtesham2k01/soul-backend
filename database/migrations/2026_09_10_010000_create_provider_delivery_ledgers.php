<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_purchase_receipts', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('store_product_id')->constrained()->restrictOnDelete();
            $table->string('platform', 20);
            $table->char('receipt_hash', 64)->unique();
            $table->text('encrypted_receipt');
            $table->string('status', 24)->default('pending');
            $table->string('provider_transaction_id', 190)->nullable();
            $table->string('provider_original_transaction_id', 190)->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->string('failure_code', 80)->nullable();
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->timestamp('next_attempt_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'next_attempt_at']);
            $table->index(['user_id', 'created_at']);
            $table->unique(['platform', 'provider_transaction_id']);
        });

        Schema::create('store_webhook_events', function (Blueprint $table): void {
            $table->id();
            $table->string('platform', 20);
            $table->char('event_hash', 64);
            $table->string('provider_event_id', 190)->nullable();
            $table->string('event_type', 100)->nullable();
            $table->text('encrypted_payload');
            $table->string('status', 24)->default('pending');
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->timestamp('processed_at')->nullable();
            $table->string('failure_code', 80)->nullable();
            $table->timestamps();
            $table->unique(['platform', 'event_hash']);
            $table->index(['status', 'created_at']);
        });

        Schema::create('notification_delivery_attempts', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_notification_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('channel', 20);
            $table->string('provider', 30);
            $table->char('deduplication_key', 64)->unique();
            $table->string('status', 24)->default('pending');
            $table->unsignedSmallInteger('attempts')->default(0);
            $table->timestamp('next_attempt_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->string('provider_message_id', 190)->nullable();
            $table->string('failure_code', 80)->nullable();
            $table->timestamps();
            $table->index(['status', 'next_attempt_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_delivery_attempts');
        Schema::dropIfExists('store_webhook_events');
        Schema::dropIfExists('store_purchase_receipts');
    }
};
