<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('profile_verification_cases', function (Blueprint $table): void {
            $table->string('requirement', 16)->default('optional')->after('type');
            $table->timestamp('verified_at')->nullable()->after('reviewed_at');
            $table->index(['user_id', 'type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('profile_verification_cases', function (Blueprint $table): void {
            $table->dropIndex(['user_id', 'type', 'status']);
            $table->dropColumn(['requirement', 'verified_at']);
        });
    }
};
