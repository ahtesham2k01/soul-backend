<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('account_privacy_settings', function (Blueprint $table): void {
            $table->boolean('screenshot_protection_enabled')->default(true);
        });

        Schema::table('profile_photo_uploads', function (Blueprint $table): void {
            $table->string('delivery_type', 20)->default('upload');
        });

        Schema::table('profile_photos', function (Blueprint $table): void {
            $table->string('delivery_type', 20)->default('upload');
            $table->string('format', 12)->nullable();
        });

        Schema::create('private_photo_access_requests', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('match_id')->constrained('user_matches')->cascadeOnDelete();
            $table->foreignId('owner_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('requester_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 16)->default('pending');
            $table->timestamp('decided_at')->nullable();
            $table->timestamp('revoked_at')->nullable();
            $table->timestamps();
            $table->unique(['match_id', 'owner_user_id', 'requester_user_id'], 'private_photo_request_unique');
            $table->index(['owner_user_id', 'status', 'id'], 'private_photo_inbox_index');
            $table->index(['requester_user_id', 'status', 'id'], 'private_photo_outbox_index');
        });

        Schema::create('private_photo_capture_events', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('private_photo_access_request_id')->constrained()->cascadeOnDelete();
            $table->foreignId('profile_photo_id')->constrained()->cascadeOnDelete();
            $table->foreignId('owner_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('viewer_user_id')->constrained('users')->cascadeOnDelete();
            $table->ulid('client_event_id');
            $table->string('event_type', 24);
            $table->timestamp('occurred_at');
            $table->timestamps();
            $table->unique(['viewer_user_id', 'client_event_id'], 'private_photo_capture_idempotency');
            $table->index(['owner_user_id', 'occurred_at'], 'private_photo_capture_owner_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('private_photo_capture_events');
        Schema::dropIfExists('private_photo_access_requests');
        Schema::table('profile_photos', fn (Blueprint $table) => $table->dropColumn(['delivery_type', 'format']));
        Schema::table('profile_photo_uploads', fn (Blueprint $table) => $table->dropColumn('delivery_type'));
        Schema::table('account_privacy_settings', fn (Blueprint $table) => $table->dropColumn('screenshot_protection_enabled'));
    }
};
