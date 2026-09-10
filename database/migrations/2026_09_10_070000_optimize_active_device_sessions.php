<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('personal_access_tokens', fn (Blueprint $table) => $table->index(
            ['tokenable_type', 'tokenable_id', 'expires_at', 'last_used_at'],
            'tokens_owner_expiry_activity_index',
        ));
    }

    public function down(): void
    {
        Schema::table('personal_access_tokens', fn (Blueprint $table) => $table->dropIndex('tokens_owner_expiry_activity_index'));
    }
};
