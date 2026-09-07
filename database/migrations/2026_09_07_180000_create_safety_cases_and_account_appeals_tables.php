<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_reports', function (Blueprint $table): void {
            $table->string('reporter_action', 24)->default('report_only')->after('details');
            $table->timestamp('reviewed_at')->nullable()->after('status');
            $table->foreignId('reviewed_by_admin_id')->nullable()->after('reviewed_at')->constrained('users')->nullOnDelete();
        });

        Schema::create('safety_cases', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('source_report_id')->nullable()->constrained('user_reports')->nullOnDelete();
            $table->string('type', 40);
            $table->string('severity', 16);
            $table->string('status', 24)->default('open');
            $table->string('reason', 500);
            $table->string('previous_profile_status', 32)->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'severity', 'created_at']);
            $table->index(['user_id', 'status']);
        });

        Schema::create('account_appeals', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('statement');
            $table->string('status', 24)->default('pending');
            $table->timestamp('submitted_at');
            $table->timestamp('resolved_at')->nullable();
            $table->foreignId('resolved_by_admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('resolution_reason', 1000)->nullable();
            $table->timestamps();
            $table->unique('user_id');
            $table->index(['status', 'submitted_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('account_appeals');
        Schema::dropIfExists('safety_cases');
        Schema::table('user_reports', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('reviewed_by_admin_id');
            $table->dropColumn(['reporter_action', 'reviewed_at']);
        });
    }
};
