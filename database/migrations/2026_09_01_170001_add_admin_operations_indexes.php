<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('admin_audit_logs', function (Blueprint $table): void {
            $table->ulid('public_id')->nullable()->after('id');
        });

        DB::table('admin_audit_logs')->orderBy('id')->eachById(
            fn ($log) => DB::table('admin_audit_logs')->where('id', $log->id)
                ->update(['public_id' => (string) Str::ulid()]),
        );

        Schema::table('admin_audit_logs', function (Blueprint $table): void {
            $table->unique('public_id');
            $table->index(['action', 'id'], 'admin_audit_logs_action_feed_index');
        });
    }

    public function down(): void
    {
        Schema::table('admin_audit_logs', function (Blueprint $table): void {
            $table->dropIndex('admin_audit_logs_action_feed_index');
            $table->dropUnique(['public_id']);
            $table->dropColumn('public_id');
        });
    }
};
