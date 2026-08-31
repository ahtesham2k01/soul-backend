<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_religion_profiles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')
                ->unique()
                ->constrained()
                ->cascadeOnDelete();
            $table->foreignId('selected_node_id')
                ->constrained('religion_taxonomy_nodes')
                ->restrictOnDelete();
            $table->char('country_code', 2)->nullable();
            $table->timestamps();

            $table->index(['selected_node_id', 'country_code']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_religion_profiles');
    }
};
