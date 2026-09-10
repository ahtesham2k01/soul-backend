<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', fn (Blueprint $table) => $table->index(['status', 'id'], 'users_status_feed_index'));
        Schema::table('profile_decisions', fn (Blueprint $table) => $table->index(['target_user_id', 'decision', 'id'], 'profile_decisions_inbox_index'));
        Schema::table('user_matches', function (Blueprint $table): void {
            $table->index(['first_user_id', 'status', 'matched_at', 'id'], 'matches_first_user_feed_index');
            $table->index(['second_user_id', 'status', 'matched_at', 'id'], 'matches_second_user_feed_index');
        });
        Schema::table('user_notifications', fn (Blueprint $table) => $table->index(['user_id', 'id'], 'notifications_user_feed_index'));
        Schema::table('profile_verification_cases', fn (Blueprint $table) => $table->index(['status', 'id'], 'verification_status_feed_index'));
        Schema::table('safety_cases', fn (Blueprint $table) => $table->index(['status', 'id'], 'safety_status_feed_index'));
        Schema::table('user_reports', fn (Blueprint $table) => $table->index(['status', 'id'], 'reports_status_feed_index'));
        Schema::table('account_appeals', fn (Blueprint $table) => $table->index(['status', 'id'], 'appeals_status_feed_index'));
    }

    public function down(): void
    {
        Schema::table('users', fn (Blueprint $table) => $table->dropIndex('users_status_feed_index'));
        Schema::table('profile_decisions', fn (Blueprint $table) => $table->dropIndex('profile_decisions_inbox_index'));
        Schema::table('user_matches', function (Blueprint $table): void {
            $table->dropIndex('matches_first_user_feed_index');
            $table->dropIndex('matches_second_user_feed_index');
        });
        Schema::table('user_notifications', fn (Blueprint $table) => $table->dropIndex('notifications_user_feed_index'));
        Schema::table('profile_verification_cases', fn (Blueprint $table) => $table->dropIndex('verification_status_feed_index'));
        Schema::table('safety_cases', fn (Blueprint $table) => $table->dropIndex('safety_status_feed_index'));
        Schema::table('user_reports', fn (Blueprint $table) => $table->dropIndex('reports_status_feed_index'));
        Schema::table('account_appeals', fn (Blueprint $table) => $table->dropIndex('appeals_status_feed_index'));
    }
};
