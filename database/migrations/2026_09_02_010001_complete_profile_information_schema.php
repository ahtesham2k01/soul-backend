<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->string('religious_practice', 120)->nullable()->after('ethnic_origin');
            $table->string('prayer', 120)->nullable()->after('religious_practice');
            $table->string('diet', 120)->nullable()->after('prayer');
            $table->string('dress', 120)->nullable()->after('diet');
            $table->boolean('detailed_religion_visible')->default(true)->after('dress');
        });

        Schema::create('user_profile_interests', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_profile_id')->constrained()->cascadeOnDelete();
            $table->string('value', 80);
            $table->timestamps();
            $table->unique(['user_profile_id', 'value']);
        });

        Schema::create('user_profile_traits', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_profile_id')->constrained()->cascadeOnDelete();
            $table->string('value', 80);
            $table->timestamps();
            $table->unique(['user_profile_id', 'value']);
        });

        Schema::create('user_profile_withheld_fields', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_profile_id')->constrained()->cascadeOnDelete();
            $table->string('field', 64);
            $table->timestamps();
            $table->unique(['user_profile_id', 'field']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_profile_withheld_fields');
        Schema::dropIfExists('user_profile_traits');
        Schema::dropIfExists('user_profile_interests');

        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->dropColumn(['religious_practice', 'prayer', 'diet', 'dress', 'detailed_religion_visible']);
        });
    }
};
