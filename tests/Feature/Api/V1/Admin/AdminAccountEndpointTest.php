<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminAccountEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_moderator_cannot_manage_admin_accounts(): void
    {
        Sanctum::actingAs($this->admin('moderator'));

        $this->getJson('/api/v1/admin/admins')
            ->assertForbidden()->assertJsonPath('error.code', 'ADMIN_ACCESS_DENIED');
        $this->postJson('/api/v1/admin/admins', [])->assertForbidden();
    }

    public function test_super_admin_can_create_and_list_secure_admin_account(): void
    {
        $actor = $this->admin('super_admin');
        Sanctum::actingAs($actor);

        $response = $this->postJson('/api/v1/admin/admins', [
            'name' => 'Safety Moderator',
            'email' => 'moderator@example.com',
            'password' => 'SecurePassword123',
            'password_confirmation' => 'SecurePassword123',
            'role' => 'moderator',
            'reason' => 'Joining safety operations',
        ])->assertCreated()
            ->assertJsonPath('data.admin.role', 'moderator')
            ->assertJsonMissingPath('data.admin.password');

        $admin = User::query()->where('public_id', $response->json('data.admin.id'))->firstOrFail();
        $this->assertTrue(Hash::check('SecurePassword123', $admin->password));
        $this->assertNotNull($admin->email_verified_at);
        $this->assertDatabaseHas('admin_audit_logs', [
            'action' => 'admin.created',
            'subject_id' => $admin->id,
            'admin_user_id' => $actor->id,
        ]);
        $this->getJson('/api/v1/admin/admins')->assertJsonCount(2, 'data.admins');
    }

    public function test_super_admin_can_change_role_and_target_sessions_are_revoked(): void
    {
        $actor = $this->admin('super_admin');
        $target = $this->admin('moderator');
        $target->createToken('admin-api');
        Sanctum::actingAs($actor);

        $this->putJson("/api/v1/admin/admins/{$target->public_id}/role", [
            'role' => 'super_admin',
            'reason' => 'Promoted to operations lead',
        ])->assertOk()->assertJsonPath('data.admin.role', 'super_admin');

        $this->assertDatabaseMissing('personal_access_tokens', ['tokenable_id' => $target->id]);
        $this->assertDatabaseHas('admin_audit_logs', [
            'action' => 'admin.role.updated',
            'subject_id' => $target->id,
        ]);
    }

    public function test_super_admin_can_remove_other_admin_access_but_not_their_own(): void
    {
        $actor = $this->admin('super_admin');
        $target = $this->admin('moderator');
        Sanctum::actingAs($actor);

        $this->deleteJson("/api/v1/admin/admins/{$actor->public_id}", [
            'reason' => 'Self removal must fail',
        ])->assertConflict()->assertJsonPath('error.code', 'ADMIN_SELF_ACCESS_REMOVAL');

        $this->deleteJson("/api/v1/admin/admins/{$target->public_id}", [
            'reason' => 'Moderator left operations',
        ])->assertOk()->assertJsonPath('data.removed', true);

        $this->assertNull($target->refresh()->admin_role);
        $this->assertDatabaseHas('admin_audit_logs', [
            'action' => 'admin.access.removed',
            'subject_id' => $target->id,
        ]);
    }

    public function test_admin_creation_rejects_weak_password_and_duplicate_email(): void
    {
        $actor = $this->admin('super_admin');
        User::factory()->create(['email' => 'existing@example.com']);
        Sanctum::actingAs($actor);

        $this->postJson('/api/v1/admin/admins', [
            'name' => 'Duplicate',
            'email' => 'existing@example.com',
            'password' => 'weak',
            'password_confirmation' => 'weak',
            'role' => 'moderator',
            'reason' => 'Invalid account test',
        ])->assertUnprocessable();
    }

    private function admin(string $role): User
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $user->forceFill(['admin_role' => $role])->save();

        return $user;
    }
}
