<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('store_purchase_receipts', fn (Blueprint $table) => $table->text('encrypted_receipt')->nullable()->change());
        Schema::table('store_webhook_events', fn (Blueprint $table) => $table->text('encrypted_payload')->nullable()->change());
    }

    public function down(): void
    {
        DB::table('store_purchase_receipts')->whereNull('encrypted_receipt')->update(['encrypted_receipt' => encrypt('')]);
        DB::table('store_webhook_events')->whereNull('encrypted_payload')->update(['encrypted_payload' => encrypt('')]);
        Schema::table('store_purchase_receipts', fn (Blueprint $table) => $table->text('encrypted_receipt')->nullable(false)->change());
        Schema::table('store_webhook_events', fn (Blueprint $table) => $table->text('encrypted_payload')->nullable(false)->change());
    }
};
