<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('notification_broadcasts', function (Blueprint $table): void {
            $table->id(); $table->ulid('public_id')->unique();
            $table->foreignId('created_by_admin_id')->constrained('users')->restrictOnDelete();
            $table->string('title', 120); $table->text('body');
            $table->string('category', 24); $table->string('audience_type', 24);
            $table->string('audience_value', 40)->nullable(); $table->string('status', 20)->default('draft')->index();
            $table->unsignedBigInteger('estimated_recipients')->default(0);
            $table->unsignedBigInteger('delivered_count')->default(0); $table->unsignedBigInteger('read_count')->default(0);
            $table->timestamp('sent_at')->nullable(); $table->timestamp('completed_at')->nullable(); $table->timestamps();
        });
        Schema::table('user_notifications', function (Blueprint $table): void {
            $table->foreignId('broadcast_id')->nullable()->after('user_id')->constrained('notification_broadcasts')->nullOnDelete();
            $table->unique(['broadcast_id', 'user_id']);
        });
    }
    public function down(): void
    {
        Schema::table('user_notifications', fn (Blueprint $table) => $table->dropConstrainedForeignId('broadcast_id'));
        Schema::dropIfExists('notification_broadcasts');
    }
};
