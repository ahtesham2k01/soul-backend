<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table): void {
            $table->id(); $table->ulid('public_id')->unique();
            $table->foreignId('user_match_id')->unique()->constrained()->cascadeOnDelete();
            $table->timestamp('last_message_at')->nullable(); $table->timestamps();
        });
        Schema::create('messages', function (Blueprint $table): void {
            $table->id(); $table->ulid('public_id')->unique();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_user_id')->constrained('users')->cascadeOnDelete();
            $table->text('body'); $table->timestamp('read_at')->nullable(); $table->timestamps();
            $table->index(['conversation_id', 'id']);
        });
        Schema::create('user_blocks', function (Blueprint $table): void {
            $table->id(); $table->foreignId('blocker_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('blocked_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 500)->nullable(); $table->timestamps();
            $table->unique(['blocker_user_id', 'blocked_user_id']);
            $table->index('blocked_user_id');
        });
        Schema::create('user_reports', function (Blueprint $table): void {
            $table->id(); $table->ulid('public_id')->unique();
            $table->foreignId('reporter_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('reported_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('category', 40); $table->string('details', 1000)->nullable();
            $table->string('status', 24)->default('pending'); $table->timestamps();
            $table->index(['status', 'created_at']);
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('user_reports'); Schema::dropIfExists('user_blocks');
        Schema::dropIfExists('messages'); Schema::dropIfExists('conversations');
    }
};
