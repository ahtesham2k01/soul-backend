<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('legal_acceptances', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('document_type', 24);
            $table->string('document_version', 40);
            $table->timestamp('accepted_at');
            $table->ipAddress('ip_address')->nullable();
            $table->char('device_context_hash', 64)->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'document_type', 'document_version']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('legal_acceptances');
    }
};
