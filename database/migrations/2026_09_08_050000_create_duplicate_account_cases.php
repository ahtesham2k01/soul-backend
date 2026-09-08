<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('duplicate_account_cases', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('primary_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('duplicate_user_id')->constrained('users')->cascadeOnDelete();
            $table->json('signals');
            $table->string('status', 24)->default('open');
            $table->text('resolution_note')->nullable();
            $table->foreignId('resolved_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
            $table->unique(['primary_user_id', 'duplicate_user_id']);
            $table->index(['status', 'created_at']);
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->foreignId('merged_into_user_id')->nullable()->after('status')->constrained('users')->nullOnDelete();
            $table->timestamp('merged_at')->nullable()->after('merged_into_user_id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('merged_into_user_id');
            $table->dropColumn('merged_at');
        });
        Schema::dropIfExists('duplicate_account_cases');
    }
};
