<?php

namespace Tests\Feature\Api\V1\Events;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EventEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_published_future_events_are_visible_with_locale_fallback(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $event = $this->event(['status' => 'published']);
        $this->event(['status' => 'draft']);
        Sanctum::actingAs($user);
        $this->withHeader('Accept-Language', 'ur')->getJson('/api/v1/events')->assertOk()
            ->assertJsonCount(1, 'data.events')->assertJsonPath('data.events.0.id', $event->public_id)
            ->assertJsonPath('data.events.0.title', 'Community Meetup')->assertJsonMissingPath('data.events.0.online_url');
    }

    public function test_join_is_idempotent_capacity_safe_and_online_url_is_member_only(): void
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $event = $this->event(['type' => 'online', 'capacity' => 1, 'online_url' => 'https://example.test/room', 'status' => 'published']);
        Sanctum::actingAs($first);
        $this->postJson("/api/v1/events/{$event->public_id}/registration")->assertCreated()->assertJsonPath('data.duplicate', false);
        $this->postJson("/api/v1/events/{$event->public_id}/registration")->assertOk()->assertJsonPath('data.duplicate', true);
        $this->getJson("/api/v1/events/{$event->public_id}")->assertJsonPath('data.event.online_url', 'https://example.test/room');
        Sanctum::actingAs($second);
        $this->postJson("/api/v1/events/{$event->public_id}/registration")->assertStatus(409)->assertJsonPath('error.code', 'EVENT_FULL');
        Sanctum::actingAs($first);
        $this->deleteJson("/api/v1/events/{$event->public_id}/registration")->assertOk()->assertJsonPath('data.left', true);
        $this->deleteJson("/api/v1/events/{$event->public_id}/registration")->assertOk()->assertJsonPath('data.left', false);
        $this->assertDatabaseHas('events', ['id' => $event->id, 'registration_count' => 0]);
    }

    public function test_event_reporting_is_private_and_idempotent(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $event = $this->event(['status' => 'published']);
        Sanctum::actingAs($user);
        $this->postJson("/api/v1/events/{$event->public_id}/report", ['category' => 'unsafe'])->assertCreated()->assertJsonPath('data.duplicate', false);
        $this->postJson("/api/v1/events/{$event->public_id}/report", ['category' => 'unsafe'])->assertOk()->assertJsonPath('data.duplicate', true);
        $this->assertDatabaseCount('event_reports', 1);
    }

    private function event(array $attributes): Event
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE, 'admin_role' => 'super_admin']);
        $event = Event::query()->create(array_merge(['created_by_admin_id' => $admin->id, 'type' => 'physical', 'starts_at' => now()->addDay(), 'timezone' => 'UTC', 'city' => 'Karachi', 'country_code' => 'PK'], $attributes));
        $event->translations()->create(['locale' => 'en', 'title' => 'Community Meetup', 'description' => 'A safe community gathering.']);

        return $event;
    }
}
