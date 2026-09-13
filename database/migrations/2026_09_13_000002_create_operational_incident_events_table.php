<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('operational_incident_events', function (Blueprint $table): void {
            $table->id();
            $table->ulid('public_id')->unique();
            $table->foreignId('operational_incident_id')->constrained()->cascadeOnDelete();
            $table->string('type', 32);
            $table->string('severity', 16);
            $table->unsignedBigInteger('current_value');
            $table->unsignedBigInteger('threshold');
            $table->foreignId('admin_user_id')->nullable()->constrained('users')->restrictOnDelete();
            $table->string('reason', 1000)->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['operational_incident_id', 'created_at'], 'operational_incident_events_timeline_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('operational_incident_events');
    }
};
