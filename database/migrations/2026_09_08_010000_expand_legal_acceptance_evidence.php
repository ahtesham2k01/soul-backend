<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('legal_acceptances', function (Blueprint $table): void {
            $table->string('accepted_via', 32)->default('onboarding')->after('accepted_at');
            $table->string('locale', 16)->nullable()->after('accepted_via');
            $table->index(['document_type', 'document_version']);
        });
    }

    public function down(): void
    {
        Schema::table('legal_acceptances', function (Blueprint $table): void {
            $table->dropIndex(['document_type', 'document_version']);
            $table->dropColumn(['accepted_via', 'locale']);
        });
    }
};
