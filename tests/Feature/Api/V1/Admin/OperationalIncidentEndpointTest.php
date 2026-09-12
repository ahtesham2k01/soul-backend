<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\OperationalIncident;
use App\Models\User;
use App\Support\Operations\OperationalIncidentManager;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OperationalIncidentEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_warning_is_recorded_and_super_admin_can_acknowledge_then_resolve_it(): void
    {
        app(OperationalIncidentManager::class)->record(['warnings' => [['code' => 'QUEUE_DEPTH_HIGH', 'severity' => 'critical', 'value' => 50, 'threshold' => 5]]]);
        $incident = OperationalIncident::firstOrFail();
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/admin/operations/incidents/'.$incident->public_id, ['decision' => 'acknowledge', 'reason' => 'Investigating queue worker capacity'])->assertOk()->assertJsonPath('data.incident.status', 'acknowledged');
        $this->putJson('/api/v1/admin/operations/incidents/'.$incident->public_id, ['decision' => 'resolve', 'reason' => 'Queue workers restored and backlog cleared'])->assertOk()->assertJsonPath('data.incident.status', 'resolved');
        $this->assertDatabaseCount('admin_audit_logs', 2);
        $this->getJson('/api/v1/admin/operations')
            ->assertOk()
            ->assertJsonPath('data.operational_incidents.0.status', 'resolved')
            ->assertJsonPath('data.recent_provider_recoveries.0.action', 'operational_incident.resolved')
            ->assertJsonMissingPath('data.recent_provider_recoveries.0.subject_id');
        $this->putJson('/api/v1/admin/operations/incidents/'.$incident->public_id, ['decision' => 'resolve', 'reason' => 'Attempt duplicate resolution'])->assertConflict();
    }

    public function test_moderator_cannot_change_operational_incident(): void
    {
        $incident = OperationalIncident::create(['fingerprint' => hash('sha256', 'TEST'), 'code' => 'TEST', 'severity' => 'warning', 'status' => 'open', 'current_value' => 2, 'threshold' => 1, 'first_detected_at' => now(), 'last_detected_at' => now()]);
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'moderator']));
        $this->putJson('/api/v1/admin/operations/incidents/'.$incident->public_id, ['decision' => 'acknowledge', 'reason' => 'Unauthorized operations attempt'])->assertForbidden();
    }
}
