<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void { Schema::table('users',fn(Blueprint $t)=>$t->string('admin_role',24)->nullable()->index()); Schema::create('admin_audit_logs',function(Blueprint $t): void { $t->id(); $t->foreignId('admin_user_id')->constrained('users')->restrictOnDelete(); $t->string('action',80); $t->string('subject_type',80); $t->unsignedBigInteger('subject_id'); $t->json('before')->nullable(); $t->json('after')->nullable(); $t->string('reason',1000)->nullable(); $t->string('ip_address',45)->nullable(); $t->timestamp('created_at'); $t->index(['subject_type','subject_id']); $t->index(['admin_user_id','created_at']); }); }
 public function down(): void { Schema::dropIfExists('admin_audit_logs'); Schema::table('users',fn(Blueprint $t)=>$t->dropColumn('admin_role')); }
};
