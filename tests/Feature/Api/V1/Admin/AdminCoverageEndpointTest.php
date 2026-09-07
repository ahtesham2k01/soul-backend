<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\SpokenLanguage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminCoverageEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_super_admin_can_override_existing_translation_and_change_spoken_language_catalog(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        SpokenLanguage::create(['code' => 'en', 'name' => 'English', 'native_name' => 'English', 'is_active' => true, 'sort_order' => 1]);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/admin/catalogs/translations', ['locale' => 'ur', 'key' => 'common.continue', 'value' => 'Agay chalein', 'reason' => 'Improve tested translation'])->assertOk();
        $this->getJson('/api/v1/bootstrap?locale=ur')->assertJsonFragment(['common.continue' => 'Agay chalein']);
        $this->putJson('/api/v1/admin/catalogs/spoken-languages/en', ['name' => 'English', 'native_name' => 'English', 'is_active' => false, 'sort_order' => 2, 'reason' => 'Temporarily hide catalog option'])->assertOk();
        $this->assertDatabaseHas('spoken_languages', ['code' => 'en', 'is_active' => false, 'sort_order' => 2]);
        $this->assertDatabaseCount('admin_audit_logs', 2);
    }

    public function test_translation_admin_cannot_create_unknown_client_key(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        Sanctum::actingAs($admin);
        $this->putJson('/api/v1/admin/catalogs/translations', ['locale' => 'en', 'key' => 'invented.key', 'value' => 'Unsafe drift', 'reason' => 'Try unknown key'])->assertUnprocessable();
    }

    public function test_operations_dashboard_exposes_counts_without_provider_ids_or_export_files(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $member->socialAccounts()->create(['provider' => 'google', 'provider_user_id' => 'provider-secret', 'provider_email' => 'member@example.test', 'provider_email_verified' => true]);
        $member->privacySetting()->create(['incognito' => true, 'profile_paused' => true, 'hide_contacts' => true]);
        $member->dataExportRequests()->create(['status' => 'completed', 'file_path' => 'private/secret.json', 'expires_at' => now()->addDay()]);
        $member->deletionRequests()->create(['status' => 'scheduled', 'scheduled_for' => now()->addDays(30)]);
        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/admin/operations')->assertOk()
            ->assertJsonPath('data.social_accounts.google', 1)
            ->assertJsonPath('data.privacy.paused_profiles', 1)
            ->assertJsonPath('data.scheduled_deletions.0.user.email', $member->email)
            ->assertJsonMissing(['provider_user_id' => 'provider-secret'])
            ->assertJsonMissing(['file_path' => 'private/secret.json']);
    }

    public function test_moderator_and_member_cannot_access_super_admin_configuration(): void
    {
        foreach (['moderator', null] as $role) {
            Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => $role]));
            $this->getJson('/api/v1/admin/catalogs')->assertForbidden();
            $this->getJson('/api/v1/admin/operations')->assertForbidden();
        }
    }
}
