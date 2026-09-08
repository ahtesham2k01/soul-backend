<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DuplicateAccountEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_super_admin_can_review_and_safely_merge_auth_only_duplicate(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        $primary = User::factory()->create(['status' => User::STATUS_ACTIVE, 'email' => null, 'email_verified_at' => null]);
        $duplicate = User::factory()->create(['status' => User::STATUS_ACTIVE, 'email' => 'duplicate@example.test']);
        $duplicate->socialAccounts()->create(['provider' => 'google', 'provider_user_id' => 'google-duplicate', 'provider_email' => 'same-person@example.test', 'provider_email_verified' => true]);
        $primary->socialAccounts()->create(['provider' => 'apple', 'provider_user_id' => 'apple-primary', 'provider_email' => 'same-person@example.test', 'provider_email_verified' => true]);
        Sanctum::actingAs($admin);

        $case = $this->postJson('/api/v1/admin/duplicate-accounts', ['primary_user_id' => $primary->public_id, 'duplicate_user_id' => $duplicate->public_id, 'reason' => 'Verified owner requested account consolidation'])
            ->assertCreated()->assertJsonPath('data.case.signals.matching_social_email', true)
            ->assertJsonPath('data.case.merge_assessment.safe_to_merge', true)->json('data.case.id');
        $this->putJson('/api/v1/admin/duplicate-accounts/'.$case, ['decision' => 'merge', 'keep_user_id' => $primary->public_id, 'confirmation' => 'MERGE ACCOUNTS', 'reason' => 'Ownership evidence verified through support workflow'])
            ->assertOk()->assertJsonPath('data.case.status', 'merged');
        $this->assertDatabaseHas('users', ['id' => $duplicate->id, 'status' => 'merged', 'merged_into_user_id' => $primary->id, 'email' => null]);
        $this->assertDatabaseHas('users', ['id' => $primary->id, 'email' => 'duplicate@example.test']);
        $this->assertDatabaseHas('social_accounts', ['user_id' => $primary->id, 'provider' => 'google']);
        $this->assertDatabaseCount('admin_audit_logs', 2);
    }

    public function test_merge_is_blocked_when_duplicate_has_profile_data(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        $primary = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $duplicate = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $duplicate->profile()->create();
        Sanctum::actingAs($admin);
        $case = $this->postJson('/api/v1/admin/duplicate-accounts', ['primary_user_id' => $primary->public_id, 'duplicate_user_id' => $duplicate->public_id, 'reason' => 'Review a suspected duplicate account'])->json('data.case.id');
        $this->putJson('/api/v1/admin/duplicate-accounts/'.$case, ['decision' => 'merge', 'keep_user_id' => $primary->public_id, 'confirmation' => 'MERGE ACCOUNTS', 'reason' => 'Attempt merge after duplicate account review'])
            ->assertStatus(409)->assertJsonPath('error.code', 'UNSAFE_ACCOUNT_MERGE')->assertJsonFragment(['duplicate_has_profile']);
        $this->assertDatabaseHas('users', ['id' => $duplicate->id, 'status' => User::STATUS_ACTIVE]);
    }

    public function test_moderator_cannot_merge_accounts(): void
    {
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'moderator']));
        $this->getJson('/api/v1/admin/duplicate-accounts')->assertForbidden();
    }
}
