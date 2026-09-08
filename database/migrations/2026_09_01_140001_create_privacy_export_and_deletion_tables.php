<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void {
  Schema::create('account_privacy_settings',function(Blueprint $t): void{$t->id();$t->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();$t->boolean('show_age')->default(true);$t->boolean('show_city')->default(true);$t->boolean('read_receipts')->default(true);$t->boolean('discoverable')->default(true);$t->timestamps();});
  Schema::create('data_export_requests',function(Blueprint $t): void{$t->id();$t->ulid('public_id')->unique();$t->foreignId('user_id')->constrained()->cascadeOnDelete();$t->string('status',24)->default('pending');$t->string('file_path')->nullable();$t->timestamp('completed_at')->nullable();$t->timestamp('expires_at')->nullable();$t->timestamps();$t->index(['user_id','created_at']);});
  Schema::create('account_deletion_requests',function(Blueprint $t): void{$t->id();$t->ulid('public_id')->unique();$t->foreignId('user_id')->constrained()->cascadeOnDelete();$t->string('status',24)->default('scheduled');$t->string('previous_profile_status',32)->nullable();$t->timestamp('scheduled_for');$t->timestamp('cancelled_at')->nullable();$t->timestamps();$t->index(['status','scheduled_for']);});
 }
 public function down(): void {Schema::dropIfExists('account_deletion_requests');Schema::dropIfExists('data_export_requests');Schema::dropIfExists('account_privacy_settings');}
};
