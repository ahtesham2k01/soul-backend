<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void {
  Schema::create('user_devices', function(Blueprint $t): void { $t->id(); $t->ulid('public_id')->unique(); $t->foreignId('user_id')->constrained()->cascadeOnDelete(); $t->string('platform',12); $t->text('push_token'); $t->char('token_hash',64)->unique(); $t->string('device_name',120)->nullable(); $t->timestamp('last_seen_at'); $t->timestamp('revoked_at')->nullable(); $t->timestamps(); $t->index(['user_id','revoked_at']); });
  Schema::create('notification_preferences', function(Blueprint $t): void { $t->id(); $t->foreignId('user_id')->unique()->constrained()->cascadeOnDelete(); $t->boolean('new_matches')->default(true); $t->boolean('new_messages')->default(true); $t->boolean('safety_updates')->default(true); $t->boolean('marketing')->default(false); $t->timestamps(); });
  Schema::create('user_notifications', function(Blueprint $t): void { $t->id(); $t->ulid('public_id')->unique(); $t->foreignId('user_id')->constrained()->cascadeOnDelete(); $t->string('type',40); $t->json('data'); $t->timestamp('read_at')->nullable(); $t->timestamps(); $t->index(['user_id','read_at','id']); });
 }
 public function down(): void { Schema::dropIfExists('user_notifications'); Schema::dropIfExists('notification_preferences'); Schema::dropIfExists('user_devices'); }
};
