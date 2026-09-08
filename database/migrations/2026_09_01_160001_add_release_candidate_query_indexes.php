<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->index(
                ['profile_status', 'gender', 'country_code', 'date_of_birth', 'id'],
                'user_profiles_candidate_lookup_index',
            );
        });

    }

    public function down(): void
    {
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->dropIndex('user_profiles_candidate_lookup_index');
        });
    }
};
