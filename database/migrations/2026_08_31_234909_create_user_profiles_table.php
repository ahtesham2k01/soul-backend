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
        Schema::create('user_profiles', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_id')
                ->unique()
                ->constrained()
                ->cascadeOnDelete();
            $table->string('profile_status', 32)
                ->default('draft')
                ->index();

            $table->string('first_name', 80)->nullable();
            $table->date('date_of_birth')->nullable();
            $table->string('gender', 12)->nullable();
            $table->string('city_name', 120)->nullable();
            $table->char('country_code', 2)->nullable();
            $table->char('nationality_country_code', 2)->nullable();
            $table->string('marital_status', 32)->nullable();
            $table->string('profession_status', 64)->nullable();
            $table->string('smoking', 32)->nullable();
            $table->string('alcohol', 32)->nullable();
            $table->string('current_children', 32)->nullable();
            $table->string('future_children', 32)->nullable();

            $table->text('bio')->nullable();
            $table->string('education', 120)->nullable();
            $table->unsignedSmallInteger('height_cm')->nullable();
            $table->string('job_title', 120)->nullable();
            $table->string('employer', 160)->nullable();
            $table->string('grew_up_in', 120)->nullable();
            $table->string('ethnic_origin', 120)->nullable();
            $table->string('relocation_preference', 64)->nullable();
            $table->string('family_involvement_preference', 64)->nullable();
            $table->timestamps();

            $table->index(
                ['profile_status', 'gender', 'country_code'],
                'user_profiles_discovery_index',
            );
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_profiles');
    }
};
