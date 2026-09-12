<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('operational_incidents', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->string('fingerprint', 64)->unique();
            $table->string('code', 80);
            $table->string('severity', 16);
            $table->string('status', 24)->default('open');
            $table->unsignedBigInteger('current_value');
            $table->unsignedBigInteger('threshold');
            $table->timestamp('first_detected_at');
            $table->timestamp('last_detected_at');
            $table->foreignId('acknowledged_by_admin_id')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('acknowledged_at')->nullable();
            $table->foreignId('resolved_by_admin_id')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->string('resolution_reason', 1000)->nullable();
            $table->timestamps();
            $table->index(['status', 'severity', 'last_detected_at'], 'operational_incidents_active_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('operational_incidents');
    }
};
