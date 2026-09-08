<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profile_catalog_items', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('type', 20);
            $table->string('key', 80);
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->foreignId('updated_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['type', 'key']);
            $table->index(['type', 'is_active', 'sort_order']);
        });

        Schema::create('profile_catalog_translations', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('profile_catalog_item_id')->constrained()->cascadeOnDelete();
            $table->string('locale', 12);
            $table->string('label', 120);
            $table->timestamps();
            $table->unique(['profile_catalog_item_id', 'locale']);
        });

        Schema::table('user_profile_interests', function (Blueprint $table): void {
            $table->foreignId('profile_catalog_item_id')->nullable()->after('user_profile_id')
                ->constrained()->nullOnDelete();
            $table->index(['user_profile_id', 'profile_catalog_item_id']);
        });

        Schema::table('user_profile_traits', function (Blueprint $table): void {
            $table->foreignId('profile_catalog_item_id')->nullable()->after('user_profile_id')
                ->constrained()->nullOnDelete();
            $table->index(['user_profile_id', 'profile_catalog_item_id']);
        });

        Schema::create('help_categories', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('key', 80)->unique();
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->foreignId('updated_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('help_category_translations', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('help_category_id')->constrained()->cascadeOnDelete();
            $table->string('locale', 12);
            $table->string('name', 120);
            $table->text('description')->nullable();
            $table->timestamps();
            $table->unique(['help_category_id', 'locale']);
        });

        Schema::create('support_tickets', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('help_category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('subject', 160);
            $table->string('status', 24)->default('open');
            $table->string('priority', 16)->default('normal');
            $table->foreignId('assigned_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('last_message_at');
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'status', 'last_message_at']);
            $table->index(['status', 'priority', 'last_message_at']);
        });

        Schema::create('support_ticket_messages', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('support_ticket_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('sender_role', 20);
            $table->text('body');
            $table->boolean('is_internal')->default(false);
            $table->timestamps();
            $table->index(['support_ticket_id', 'id']);
        });

        Schema::create('support_ticket_attachments', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('support_ticket_message_id')->constrained()->cascadeOnDelete();
            $table->string('disk', 40);
            $table->string('path', 500);
            $table->string('original_name', 255);
            $table->string('mime_type', 120);
            $table->unsignedBigInteger('size_bytes');
            $table->char('sha256', 64);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_ticket_attachments');
        Schema::dropIfExists('support_ticket_messages');
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('help_category_translations');
        Schema::dropIfExists('help_categories');

        Schema::table('user_profile_traits', function (Blueprint $table): void {
            $table->dropIndex(['user_profile_id', 'profile_catalog_item_id']);
            $table->dropConstrainedForeignId('profile_catalog_item_id');
        });
        Schema::table('user_profile_interests', function (Blueprint $table): void {
            $table->dropIndex(['user_profile_id', 'profile_catalog_item_id']);
            $table->dropConstrainedForeignId('profile_catalog_item_id');
        });

        Schema::dropIfExists('profile_catalog_translations');
        Schema::dropIfExists('profile_catalog_items');
    }
};
