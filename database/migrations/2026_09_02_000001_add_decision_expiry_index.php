<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('profile_decisions', function (Blueprint $table): void {
            $table->index(
                ['actor_user_id', 'decision', 'updated_at', 'target_user_id'],
                'profile_decisions_visibility_expiry_index',
            );
        });
    }

    public function down(): void
    {
        Schema::table('profile_decisions', function (Blueprint $table): void {
            $table->dropIndex('profile_decisions_visibility_expiry_index');
        });
    }
};
