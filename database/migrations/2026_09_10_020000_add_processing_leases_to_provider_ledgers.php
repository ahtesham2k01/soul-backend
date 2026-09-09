<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notification_delivery_attempts', function (Blueprint $table): void {
            $table->timestamp('processing_started_at')->nullable()->after('next_attempt_at')->index();
        });
        Schema::table('store_webhook_events', function (Blueprint $table): void {
            $table->timestamp('processing_started_at')->nullable()->after('attempts')->index();
        });
    }

    public function down(): void
    {
        Schema::table('notification_delivery_attempts', fn (Blueprint $table) => $table->dropColumn('processing_started_at'));
        Schema::table('store_webhook_events', fn (Blueprint $table) => $table->dropColumn('processing_started_at'));
    }
};
