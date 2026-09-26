<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('safety_cases', function (Blueprint $table): void {
            $table->string('signal_key', 64)->nullable()->after('type');
            $table->json('evidence')->nullable()->after('reason');
            $table->unsignedInteger('occurrence_count')->default(1)->after('evidence');
            $table->timestamp('first_observed_at')->nullable()->after('occurrence_count');
            $table->timestamp('last_observed_at')->nullable()->after('first_observed_at');
            $table->index(['user_id', 'type', 'signal_key', 'status'], 'safety_signal_review_lookup');
        });
        Schema::table('profile_decisions', function (Blueprint $table): void {
            $table->index(['actor_user_id', 'updated_at'], 'profile_decisions_velocity_lookup');
        });
        Schema::table('messages', function (Blueprint $table): void {
            $table->index(['sender_user_id', 'created_at', 'conversation_id'], 'messages_safety_velocity_lookup');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table): void {
            $table->dropIndex('messages_safety_velocity_lookup');
        });
        Schema::table('profile_decisions', function (Blueprint $table): void {
            $table->dropIndex('profile_decisions_velocity_lookup');
        });
        Schema::table('safety_cases', function (Blueprint $table): void {
            $table->dropIndex('safety_signal_review_lookup');
            $table->dropColumn([
                'signal_key',
                'evidence',
                'occurrence_count',
                'first_observed_at',
                'last_observed_at',
            ]);
        });
    }
};
