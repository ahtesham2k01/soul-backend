<?php

use App\Support\Privacy\PhoneLookupHasher;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('discovery_preferences', function (Blueprint $table): void {
            $table->string('location_mode', 16)->default('current')->after('religion_mode');
            $table->unsignedSmallInteger('radius_km')->nullable()->after('location_mode');
        });
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->decimal('latitude', 9, 6)->nullable()->after('country_code');
            $table->decimal('longitude', 9, 6)->nullable()->after('latitude');
            $table->timestamp('last_active_at')->nullable()->after('live_at');
            $table->index(['profile_status', 'last_active_at', 'id'], 'profile_activity_discovery_index');
            $table->index(['latitude', 'longitude'], 'profile_coordinate_index');
        });
        Schema::table('account_privacy_settings', function (Blueprint $table): void {
            $table->boolean('incognito')->default(false);
            $table->boolean('profile_paused')->default(false);
            $table->boolean('hide_contacts')->default(false);
        });
        Schema::table('users', function (Blueprint $table): void {
            $table->char('phone_lookup_hash', 64)->nullable()->unique();
        });
        Schema::create('discovery_preference_locations', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('discovery_preference_id')->constrained()->cascadeOnDelete();
            $table->char('country_code', 2);
            $table->string('city_name', 120)->nullable();
            $table->timestamps();
            $table->unique(['discovery_preference_id', 'country_code', 'city_name'], 'discovery_location_unique');
            $table->index(['country_code', 'city_name']);
        });
        Schema::create('discovery_preference_intentions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('discovery_preference_id')->constrained()->cascadeOnDelete();
            $table->string('intention', 32);
            $table->timestamps();
            $table->unique(['discovery_preference_id', 'intention'], 'discovery_intention_unique');
        });
        Schema::create('hidden_contact_hashes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->char('phone_hash', 64);
            $table->timestamps();
            $table->unique(['user_id', 'phone_hash']);
            $table->index('phone_hash');
        });

        DB::table('user_profiles')->update(['last_active_at' => DB::raw('COALESCE(live_at, created_at)')]);
        $hasher = app(PhoneLookupHasher::class);
        DB::table('users')->whereNotNull('phone')->orderBy('id')->each(function (object $user) use ($hasher): void {
            DB::table('users')->where('id', $user->id)->update(['phone_lookup_hash' => $hasher->hash($user->phone)]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hidden_contact_hashes');
        Schema::dropIfExists('discovery_preference_intentions');
        Schema::dropIfExists('discovery_preference_locations');
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('phone_lookup_hash'));
        Schema::table('account_privacy_settings', fn (Blueprint $table) => $table->dropColumn(['incognito', 'profile_paused', 'hide_contacts']));
        Schema::table('user_profiles', function (Blueprint $table): void {
            $table->dropIndex('profile_activity_discovery_index');
            $table->dropIndex('profile_coordinate_index');
            $table->dropColumn(['latitude', 'longitude', 'last_active_at']);
        });
        Schema::table('discovery_preferences', fn (Blueprint $table) => $table->dropColumn(['location_mode', 'radius_km']));
    }
};
