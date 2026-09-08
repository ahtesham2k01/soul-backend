<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notification_preferences', function (Blueprint $table): void {
            $table->boolean('push_private_photos')->default(true);
            $table->boolean('push_verification')->default(true);
            $table->boolean('push_account')->default(true);
            $table->boolean('push_marketing')->default(false);
            $table->boolean('email_new_matches')->default(true);
            $table->boolean('email_new_messages')->default(false);
            $table->boolean('email_private_photos')->default(false);
            $table->boolean('email_verification')->default(true);
            $table->boolean('email_account')->default(true);
            $table->boolean('email_marketing')->default(false);
            $table->timestamp('marketing_consented_at')->nullable();
        });
        Schema::table('user_notifications', function (Blueprint $table): void {
            $table->json('delivery_channels')->nullable()->after('data');
            $table->string('deduplication_key', 160)->nullable()->unique()->after('type');
        });
    }

    public function down(): void
    {
        Schema::table('user_notifications', function (Blueprint $table): void {
            $table->dropUnique(['deduplication_key']);
            $table->dropColumn(['delivery_channels', 'deduplication_key']);
        });
        Schema::table('notification_preferences', function (Blueprint $table): void {
            $table->dropColumn([
                'push_private_photos', 'push_verification', 'push_account', 'push_marketing',
                'email_new_matches', 'email_new_messages', 'email_private_photos',
                'email_verification', 'email_account', 'email_marketing', 'marketing_consented_at',
            ]);
        });
    }
};
