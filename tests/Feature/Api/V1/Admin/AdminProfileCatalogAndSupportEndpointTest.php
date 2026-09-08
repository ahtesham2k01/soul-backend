<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\HelpCategory;
use App\Models\User;
use Database\Seeders\ProfileAndSupportCatalogSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminProfileCatalogAndSupportEndpointTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ProfileAndSupportCatalogSeeder::class);
    }

    public function test_super_admin_manages_profile_catalog_with_audit(): void
    {
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']));
        $id = $this->postJson('/api/v1/admin/profile-catalogs/items', ['type' => 'interest', 'key' => 'gardening', 'sort_order' => 20, 'translations' => ['en' => 'Gardening', 'ur' => 'Baghbani'], 'reason' => 'Add requested profile option'])
            ->assertCreated()->json('data.item.id');
        $this->putJson('/api/v1/admin/profile-catalogs/items/'.$id, ['is_active' => false, 'sort_order' => 21, 'translations' => ['en' => 'Gardening'], 'reason' => 'Temporarily retire this option'])->assertOk();
        $this->assertDatabaseHas('profile_catalog_items', ['key' => 'gardening', 'is_active' => false]);
        $this->assertDatabaseCount('admin_audit_logs', 2);
    }

    public function test_moderator_can_manage_support_thread_but_member_cannot_access_queue(): void
    {
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($member);
        $category = HelpCategory::firstOrFail();
        $ticketId = $this->postJson('/api/v1/support/tickets', ['category_id' => $category->public_id, 'subject' => 'Need assistance', 'message' => 'Please review this issue.'])->json('data.ticket.id');
        $this->getJson('/api/v1/admin/support-tickets')->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'moderator']));
        $this->getJson('/api/v1/admin/support-tickets')->assertOk()->assertJsonPath('data.tickets.0.id', $ticketId);
        $this->putJson('/api/v1/admin/support-tickets/'.$ticketId, ['status' => 'waiting_for_member', 'priority' => 'high', 'message' => 'Please provide your app version.', 'reason' => 'Need additional diagnostic context'])->assertOk();
        $this->assertDatabaseHas('support_tickets', ['public_id' => $ticketId, 'priority' => 'high', 'status' => 'waiting_for_member']);
        $this->assertDatabaseCount('admin_audit_logs', 1);
    }
}
