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
        Schema::table('personal_access_tokens', function (Blueprint $table): void {
            $table->ulid('public_id')->nullable()->after('id');
        });

        DB::table('personal_access_tokens')
            ->whereNull('public_id')
            ->orderBy('id')
            ->eachById(function (object $token): void {
                DB::table('personal_access_tokens')
                    ->where('id', $token->id)
                    ->update(['public_id' => (string) Str::ulid()]);
            });

        Schema::table('personal_access_tokens', function (Blueprint $table): void {
            $table->unique('public_id');
        });
    }

    public function down(): void
    {
        Schema::table('personal_access_tokens', function (Blueprint $table): void {
            $table->dropUnique(['public_id']);
            $table->dropColumn('public_id');
        });
    }
};
