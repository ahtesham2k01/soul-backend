<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->timestamp('submitted_at')->nullable()->after('profile_status');
            $table->timestamp('checks_completed_at')->nullable()->after('submitted_at');
            $table->timestamp('live_at')->nullable()->after('checks_completed_at');
            $table->string('status_reason', 500)->nullable()->after('live_at');
            $table->string('correction_screen', 120)->nullable()->after('status_reason');
        });
    }

    public function down(): void
    {
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->dropColumn([
                'submitted_at', 'checks_completed_at', 'live_at',
                'status_reason', 'correction_screen',
            ]);
        });
    }
};
