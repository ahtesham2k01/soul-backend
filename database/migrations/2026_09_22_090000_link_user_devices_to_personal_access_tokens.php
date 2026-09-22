<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_devices', function (Blueprint $table): void {
            $table->foreignId('personal_access_token_id')
                ->nullable()
                ->after('user_id')
                ->constrained('personal_access_tokens')
                ->cascadeOnDelete();

            $table->index(
                ['user_id', 'personal_access_token_id', 'revoked_at'],
                'user_devices_session_revocation_index',
            );
        });
    }

    public function down(): void
    {
        Schema::table('user_devices', function (Blueprint $table): void {
            $table->dropIndex('user_devices_session_revocation_index');
            $table->dropConstrainedForeignId('personal_access_token_id');
        });
    }
};
