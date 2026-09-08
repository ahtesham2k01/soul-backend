<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\Event;
use App\Models\EventReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminEventEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_super_admin_can_create_update_and_publish_localized_event(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        Sanctum::actingAs($admin);
        $id = $this->postJson('/api/v1/admin/events', $this->payload())->assertCreated()
            ->assertJsonPath('data.event.status', 'draft')->json('data.event.id');
        $this->putJson("/api/v1/admin/events/{$id}", $this->payload(['city' => 'Lahore']))->assertOk()->assertJsonPath('data.event.city', 'Lahore');
        $this->putJson("/api/v1/admin/events/{$id}/status", ['status' => 'published', 'reason' => 'Ready for members'])->assertOk()->assertJsonPath('data.status', 'published');
        $this->assertDatabaseCount('admin_audit_logs', 3);
    }

    public function test_member_and_moderator_cannot_manage_events(): void
    {
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $moderator = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'moderator']);
        Sanctum::actingAs($member);
        $this->postJson('/api/v1/admin/events', $this->payload())->assertForbidden();
        Sanctum::actingAs($moderator);
        $this->postJson('/api/v1/admin/events', $this->payload())->assertForbidden();
    }

    public function test_admin_can_cancel_reported_event_without_exposing_reporter(): void
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        Sanctum::actingAs($admin);
        $eventId = $this->postJson('/api/v1/admin/events', $this->payload())->json('data.event.id');
        $this->putJson("/api/v1/admin/events/{$eventId}/status", ['status' => 'published', 'reason' => 'Ready for members']);
        $event = Event::where('public_id', $eventId)->firstOrFail();
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $report = EventReport::create(['event_id' => $event->id, 'reporter_user_id' => $member->id, 'category' => 'unsafe', 'status' => 'pending']);
        $this->getJson('/api/v1/admin/event-reports')->assertOk()->assertJsonMissing(['reporter_user_id' => $member->id]);
        $this->putJson("/api/v1/admin/event-reports/{$report->public_id}", ['decision' => 'cancel_event', 'reason' => 'Safety concern confirmed'])->assertOk();
        $this->assertDatabaseHas('events', ['id' => $event->id, 'status' => 'cancelled']);
    }

    private function payload(array $overrides = []): array
    {
        return array_merge(['type' => 'physical', 'starts_at' => now()->addDays(2)->toIso8601String(), 'ends_at' => now()->addDays(2)->addHours(2)->toIso8601String(), 'timezone' => 'Asia/Karachi', 'city' => 'Karachi', 'country_code' => 'PK', 'capacity' => 50, 'translations' => [['locale' => 'en', 'title' => 'SOUL Meetup', 'description' => 'Meet safely in a moderated venue.'], ['locale' => 'ur', 'title' => 'SOUL Meetup', 'description' => 'Mehfooz community meetup.']]], $overrides);
    }
}
