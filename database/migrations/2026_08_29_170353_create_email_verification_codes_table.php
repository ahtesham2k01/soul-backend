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
        Schema::create(
            'email_verification_codes',
            function (Blueprint $table): void {
                $table->id();

                $table
                    ->ulid('public_id')
                    ->unique();

                $table
                    ->char('email_hash', 64);

                $table
                    ->string('purpose', 20);

                $table
                    ->char('code_hash', 64);

                $table
                    ->unsignedTinyInteger('attempts')
                    ->default(0);

                $table->timestamp('expires_at');

                $table
                    ->timestamp('consumed_at')
                    ->nullable();

                $table->timestamps();

                $table->index(
                    [
                        'email_hash',
                        'purpose',
                        'consumed_at',
                    ],
                    'email_verification_lookup',
                );

                $table->index(
                    'expires_at',
                );
            },
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists(
            'email_verification_codes',
        );
    }
};
