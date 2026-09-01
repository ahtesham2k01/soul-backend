<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profile_decisions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('actor_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('target_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('decision', 12);
            $table->timestamps();
            $table->unique(['actor_user_id', 'target_user_id']);
            $table->index(['target_user_id', 'decision']);
        });

        Schema::create('user_matches', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('first_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('second_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('active');
            $table->timestamp('matched_at');
            $table->timestamp('ended_at')->nullable();
            $table->foreignId('ended_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['first_user_id', 'second_user_id']);
            $table->index(['status', 'matched_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_matches');
        Schema::dropIfExists('profile_decisions');
    }
};
