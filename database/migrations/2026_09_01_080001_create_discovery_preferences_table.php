<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('discovery_preferences', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('preferred_gender', 12);
            $table->unsignedTinyInteger('minimum_age')->default(18);
            $table->unsignedTinyInteger('maximum_age')->default(100);
            $table->boolean('same_country_only')->default(true);
            $table->timestamps();
            $table->index(['preferred_gender', 'minimum_age', 'maximum_age']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('discovery_preferences');
    }
};
