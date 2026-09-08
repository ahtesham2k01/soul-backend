<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profile_verification_cases', function (Blueprint $table): void {
            $table->id(); $table->ulid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 32); $table->string('status', 32)->default('pending');
            $table->string('reason', 500)->nullable(); $table->timestamp('submitted_at');
            $table->timestamp('reviewed_at')->nullable(); $table->timestamps();
            $table->index(['status', 'submitted_at']);
            $table->index(['user_id', 'created_at']);
        });
        Schema::create('verification_appeals', function (Blueprint $table): void {
            $table->id(); $table->ulid('public_id')->unique();
            $table->foreignId('profile_verification_case_id')->unique()
                ->constrained('profile_verification_cases')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('statement', 1500); $table->string('status', 24)->default('pending');
            $table->timestamp('submitted_at'); $table->timestamp('resolved_at')->nullable();
            $table->timestamps(); $table->index(['status', 'submitted_at']);
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('verification_appeals');
        Schema::dropIfExists('profile_verification_cases');
    }
};
