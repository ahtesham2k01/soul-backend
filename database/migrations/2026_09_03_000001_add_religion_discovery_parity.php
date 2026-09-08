<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('discovery_preferences', function (Blueprint $table): void {
            $table->string('religion_mode', 24)->default('my_religion')->after('same_country_only');
        });

        Schema::table('user_religion_profiles', function (Blueprint $table): void {
            $table->foreignId('root_node_id')->nullable()->after('selected_node_id')
                ->constrained('religion_taxonomy_nodes')->restrictOnDelete();
            $table->index(['root_node_id', 'user_id'], 'user_religion_root_user_index');
        });

        DB::table('user_religion_profiles')->orderBy('id')->each(function (object $profile): void {
            $selectedPath = DB::table('religion_taxonomy_nodes')->where('id', $profile->selected_node_id)->value('path');

            if (! is_string($selectedPath)) {
                return;
            }

            $rootPath = explode('/', $selectedPath, 2)[0];
            $rootId = DB::table('religion_taxonomy_nodes')->where('path', $rootPath)->value('id');

            DB::table('user_religion_profiles')->where('id', $profile->id)->update(['root_node_id' => $rootId]);
        });
    }

    public function down(): void
    {
        Schema::table('user_religion_profiles', function (Blueprint $table): void {
            $table->dropIndex('user_religion_root_user_index');
            $table->dropConstrainedForeignId('root_node_id');
        });

        Schema::table('discovery_preferences', function (Blueprint $table): void {
            $table->dropColumn('religion_mode');
        });
    }
};
