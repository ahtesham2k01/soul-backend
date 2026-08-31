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
        Schema::create('spoken_language_user_profile', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('spoken_language_id')
                ->constrained()
                ->cascadeOnDelete();
            $table->foreignId('user_profile_id')
                ->constrained()
                ->cascadeOnDelete();
            $table->timestamps();

            $table->unique([
                'spoken_language_id',
                'user_profile_id',
            ], 'spoken_language_user_profile_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('spoken_language_user_profile');
    }
};
