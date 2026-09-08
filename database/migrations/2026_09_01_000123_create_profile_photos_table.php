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
        Schema::create('profile_photos', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_profile_id')
                ->constrained()
                ->cascadeOnDelete();
            $table->unsignedTinyInteger('position');
            $table->string('visibility', 16);
            $table->string('storage_provider', 24)
                ->default('cloudinary');
            $table->string('provider_asset_id', 255);
            $table->string('moderation_status', 24)
                ->default('pending');
            $table->string('rejection_reason', 500)->nullable();
            $table->boolean('face_detected')->nullable();
            $table->boolean('screenshot_protection_enabled')
                ->default(true);
            $table->timestamps();

            $table->unique(['user_profile_id', 'position']);
            $table->unique(['storage_provider', 'provider_asset_id']);
            $table->index([
                'moderation_status',
                'created_at',
            ], 'profile_photos_moderation_queue_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('profile_photos');
    }
};
