<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create(
            'religion_taxonomy_nodes',
            function (Blueprint $table): void {
                $table->id();

                $table
                    ->ulid('public_id')
                    ->unique();

                $table
                    ->foreignId('parent_id')
                    ->nullable()
                    ->constrained('religion_taxonomy_nodes')
                    ->cascadeOnDelete();

                $table->string('type', 24);
                $table->string('slug', 80);

                $table
                    ->string('path', 400)
                    ->unique();

                $table
                    ->boolean('is_active')
                    ->default(true)
                    ->index();

                $table
                    ->unsignedSmallInteger('sort_order')
                    ->default(0);

                $table->timestamps();

                $table->index([
                    'parent_id',
                    'type',
                    'is_active',
                    'sort_order',
                ], 'religion_taxonomy_browse_index');
            },
        );

        Schema::create(
            'religion_taxonomy_translations',
            function (Blueprint $table): void {
                $table->id();

                $table
                    ->foreignId('node_id')
                    ->constrained('religion_taxonomy_nodes')
                    ->cascadeOnDelete();

                $table->string('locale', 15);
                $table->string('label', 120);
                $table->string('description', 500)->nullable();
                $table->timestamps();

                $table->unique([
                    'node_id',
                    'locale',
                ], 'religion_taxonomy_node_locale_unique');
            },
        );

        Schema::create(
            'religion_taxonomy_countries',
            function (Blueprint $table): void {
                $table->id();

                $table
                    ->foreignId('node_id')
                    ->constrained('religion_taxonomy_nodes')
                    ->cascadeOnDelete();

                $table->char('country_code', 2);
                $table->timestamps();

                $table->unique([
                    'node_id',
                    'country_code',
                ], 'religion_taxonomy_node_country_unique');
            },
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('religion_taxonomy_countries');
        Schema::dropIfExists('religion_taxonomy_translations');
        Schema::dropIfExists('religion_taxonomy_nodes');
    }
};
