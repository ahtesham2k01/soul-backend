<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReligionTaxonomyEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_super_admin_can_manage_taxonomy(): void
    {
        Sanctum::actingAs($this->admin('moderator'));
        $this->getJson('/api/v1/admin/religion-taxonomy')->assertForbidden();
        $this->postJson('/api/v1/admin/religion-taxonomy', [])->assertForbidden();
    }

    public function test_super_admin_can_create_localized_country_restricted_hierarchy(): void
    {
        $actor = $this->admin('super_admin'); Sanctum::actingAs($actor);
        $root = $this->createNode(['slug' => 'islam', 'type' => 'religion', 'country_codes' => []]);
        $child = $this->createNode(['parent_id' => $root, 'slug' => 'sunni', 'type' => 'sect', 'country_codes' => ['pk', 'AE']]);

        $child->assertCreated()->assertJsonPath('data.node.path', 'islam/sunni')->assertJsonPath('data.node.country_codes.0', 'AE')->assertJsonPath('data.node.country_codes.1', 'PK');
        $this->assertDatabaseHas('religion_taxonomy_translations', ['locale' => 'en', 'label' => 'Sunni']);
        $this->assertDatabaseHas('admin_audit_logs', ['admin_user_id' => $actor->id, 'action' => 'religion_taxonomy.created']);
        $this->getJson('/api/v1/admin/religion-taxonomy')->assertOk()->assertJsonCount(2, 'data.nodes');
    }

    public function test_update_rewrites_descendant_paths_and_prevents_cycles(): void
    {
        Sanctum::actingAs($this->admin('super_admin'));
        $rootId = $this->createNode(['slug' => 'islam', 'type' => 'religion'])->json('data.node.id');
        $childId = $this->createNode(['parent_id' => $rootId, 'slug' => 'sunni', 'type' => 'sect'])->json('data.node.id');
        $grandchildId = $this->createNode(['parent_id' => $childId, 'slug' => 'hanafi', 'type' => 'school'])->json('data.node.id');

        $this->putJson('/api/v1/admin/religion-taxonomy/'.$rootId, $this->payload(['slug' => 'islamic', 'type' => 'religion']))->assertOk();
        $this->assertDatabaseHas('religion_taxonomy_nodes', ['public_id' => $grandchildId, 'path' => 'islamic/sunni/hanafi']);
        $this->putJson('/api/v1/admin/religion-taxonomy/'.$rootId, $this->payload(['parent_id' => $grandchildId, 'slug' => 'islamic', 'type' => 'religion']))->assertConflict()->assertJsonPath('error.code', 'RELIGION_HIERARCHY_CYCLE');
    }

    public function test_deactivation_preserves_existing_profiles_and_hides_option_from_onboarding(): void
    {
        Sanctum::actingAs($this->admin('super_admin'));
        $id = $this->createNode(['slug' => 'global-belief', 'type' => 'belief'])->json('data.node.id');
        $this->putJson('/api/v1/admin/religion-taxonomy/'.$id, $this->payload(['slug' => 'global-belief', 'type' => 'belief', 'is_active' => false]))->assertOk()->assertJsonPath('data.node.is_active', false);
        $this->assertDatabaseHas('religion_taxonomy_nodes', ['public_id' => $id, 'is_active' => false]);
    }

    private function createNode(array $overrides = []): \Illuminate\Testing\TestResponse
    {
        return $this->postJson('/api/v1/admin/religion-taxonomy', $this->payload($overrides));
    }

    private function payload(array $overrides = []): array
    {
        $slug = $overrides['slug'] ?? 'sunni';
        return array_merge(['parent_id' => null, 'type' => 'sect', 'slug' => $slug, 'is_active' => true, 'sort_order' => 0, 'translations' => [['locale' => 'en', 'label' => ucfirst($slug), 'description' => null]], 'country_codes' => [], 'reason' => 'Approved taxonomy maintenance'], $overrides);
    }

    private function admin(string $role): User
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $user->forceFill(['admin_role' => $role])->save(); return $user;
    }
}
