<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('events', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('created_by_admin_id')->constrained('users')->restrictOnDelete();
            $table->string('type', 20);
            $table->string('status', 20)->default('draft');
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->string('timezone', 64)->default('UTC');
            $table->string('city', 120)->nullable();
            $table->char('country_code', 2)->nullable();
            $table->string('online_url', 2048)->nullable();
            $table->unsignedInteger('capacity')->nullable();
            $table->unsignedInteger('registration_count')->default(0);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'starts_at']);
        });
        Schema::create('event_translations', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->string('locale', 12);
            $table->string('title', 160);
            $table->text('description');
            $table->timestamps();
            $table->unique(['event_id', 'locale']);
        });
        Schema::create('event_registrations', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('joined_at');
            $table->timestamps();
            $table->unique(['event_id', 'user_id']);
        });
        Schema::create('event_reports', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('reporter_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('category', 40);
            $table->text('details')->nullable();
            $table->string('status', 20)->default('pending');
            $table->foreignId('reviewed_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
            $table->unique(['event_id', 'reporter_user_id']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('event_reports');
        Schema::dropIfExists('event_registrations');
        Schema::dropIfExists('event_translations');
        Schema::dropIfExists('events');
    }
};
