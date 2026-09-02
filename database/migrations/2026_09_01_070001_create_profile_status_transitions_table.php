<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profile_status_transitions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('actor_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('from_status', 40);
            $table->string('to_status', 40);
            $table->string('source', 120);
            $table->string('reason', 500)->nullable();
            $table->string('correction_screen', 120)->nullable();
            $table->timestamp('created_at');
            $table->index(['user_profile_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('profile_status_transitions');
    }
};
