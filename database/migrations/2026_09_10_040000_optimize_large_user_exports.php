<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('data_export_requests', fn (Blueprint $table) => $table->timestamp('processing_started_at')->nullable()->after('status')->index());
        Schema::table('messages', fn (Blueprint $table) => $table->index(['sender_user_id', 'id'], 'messages_sender_export_index'));
        Schema::table('user_matches', fn (Blueprint $table) => $table->index(['second_user_id', 'id'], 'matches_second_user_export_index'));
        Schema::table('user_reports', fn (Blueprint $table) => $table->index(['reporter_user_id', 'id'], 'reports_reporter_export_index'));
        Schema::table('event_registrations', fn (Blueprint $table) => $table->index(['user_id', 'id'], 'event_registrations_user_export_index'));
    }

    public function down(): void
    {
        Schema::table('data_export_requests', fn (Blueprint $table) => $table->dropColumn('processing_started_at'));
        Schema::table('messages', function (Blueprint $table): void {
            $table->index('sender_user_id', 'messages_sender_user_id_foreign');
            $table->dropIndex('messages_sender_export_index');
        });
        Schema::table('user_matches', function (Blueprint $table): void {
            $table->index('second_user_id', 'user_matches_second_user_id_foreign');
            $table->dropIndex('matches_second_user_export_index');
        });
        Schema::table('user_reports', function (Blueprint $table): void {
            $table->index('reporter_user_id', 'user_reports_reporter_user_id_foreign');
            $table->dropIndex('reports_reporter_export_index');
        });
        Schema::table('event_registrations', function (Blueprint $table): void {
            $table->index('user_id', 'event_registrations_user_id_foreign');
            $table->dropIndex('event_registrations_user_export_index');
        });
    }
};
