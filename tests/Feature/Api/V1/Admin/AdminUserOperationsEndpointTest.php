<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\AdminAuditLog;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminUserOperationsEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_moderator_can_search_and_inspect_users_without_internal_ids(): void
    {
        $moderator = $this->admin('moderator');
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
            'email' => 'member@example.com',
        ]);
        UserProfile::factory()->for($user)->create([
            'first_name' => 'Ayesha',
            'profile_status' => 'live',
            'country_code' => 'PK',
        ]);
        Sanctum::actingAs($moderator);

        $this->getJson('/api/v1/admin/users?search=Ayesha')
            ->assertOk()
            ->assertJsonCount(1, 'data.users')
            ->assertJsonPath('data.users.0.id', $user->public_id)
            ->assertJsonPath('data.users.0.name', 'Ayesha')
            ->assertJsonMissingPath('data.users.0.user_id');

        $this->getJson("/api/v1/admin/users/{$user->public_id}")
            ->assertOk()
            ->assertJsonPath('data.user.counts.reports_received', 0)
            ->assertJsonMissingPath('data.user.profile.user_id');
    }

    public function test_only_super_admin_can_change_user_status(): void
    {
        $moderator = $this->admin('moderator');
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($moderator);

        $this->putJson("/api/v1/admin/users/{$user->public_id}/status", [
            'status' => User::STATUS_SUSPENDED,
            'reason' => 'Safety review required',
        ])->assertForbidden()->assertJsonPath('error.code', 'ADMIN_ACCESS_DENIED');

        $this->assertSame(User::STATUS_ACTIVE, $user->refresh()->status);
    }

    public function test_super_admin_suspension_revokes_access_pauses_profile_and_is_audited(): void
    {
        $admin = $this->admin('super_admin');
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create(['profile_status' => 'live']);
        $user->createToken('mobile');
        Sanctum::actingAs($admin);

        $this->putJson("/api/v1/admin/users/{$user->public_id}/status", [
            'status' => User::STATUS_SUSPENDED,
            'reason' => 'Confirmed safety escalation',
        ])->assertOk()
            ->assertJsonPath('data.user.status', User::STATUS_SUSPENDED)
            ->assertJsonPath('data.user.profile_status', 'paused_verification');

        $this->assertDatabaseMissing('personal_access_tokens', ['tokenable_id' => $user->id]);
        $this->assertDatabaseHas('admin_audit_logs', [
            'admin_user_id' => $admin->id,
            'action' => 'user.status.suspended',
            'subject_id' => $user->id,
            'reason' => 'Confirmed safety escalation',
        ]);
    }

    public function test_super_admin_cannot_change_own_status(): void
    {
        $admin = $this->admin('super_admin');
        Sanctum::actingAs($admin);

        $this->putJson("/api/v1/admin/users/{$admin->public_id}/status", [
            'status' => User::STATUS_BLOCKED,
            'reason' => 'Self action must fail',
        ])->assertConflict()->assertJsonPath('error.code', 'ADMIN_SELF_STATUS_CHANGE');
    }

    public function test_admin_accounts_cannot_be_changed_through_member_status_controls(): void
    {
        $admin = $this->admin('super_admin');
        $otherAdmin = $this->admin('moderator');
        Sanctum::actingAs($admin);

        $this->putJson("/api/v1/admin/users/{$otherAdmin->public_id}/status", [
            'status' => User::STATUS_BLOCKED,
            'reason' => 'Wrong administration flow',
        ])->assertConflict()->assertJsonPath('error.code', 'ADMIN_ACCOUNT_PROTECTED');

        $this->assertSame(User::STATUS_ACTIVE, $otherAdmin->refresh()->status);
    }

    public function test_audit_feed_supports_filters_and_hides_internal_subject_identifiers(): void
    {
        $admin = $this->admin('super_admin');
        $target = User::factory()->create();
        $log = AdminAuditLog::query()->create([
            'admin_user_id' => $admin->id,
            'action' => 'user.status.suspended',
            'subject_type' => User::class,
            'subject_id' => $target->id,
            'before' => ['status' => 'active'],
            'after' => ['status' => 'suspended'],
            'reason' => 'Test audit',
            'ip_address' => '127.0.0.1',
        ]);
        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/admin/audit-logs?action=user.status')
            ->assertOk()
            ->assertJsonCount(1, 'data.audit_logs')
            ->assertJsonPath('data.audit_logs.0.id', $log->public_id)
            ->assertJsonPath('data.audit_logs.0.admin.id', $admin->public_id)
            ->assertJsonMissingPath('data.audit_logs.0.subject_id')
            ->assertJsonMissingPath('data.audit_logs.0.ip_address');
    }

    private function admin(string $role): User
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $user->forceFill(['admin_role' => $role])->save();

        return $user;
    }
}
