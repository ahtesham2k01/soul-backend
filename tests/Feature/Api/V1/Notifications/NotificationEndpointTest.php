<?php

namespace Tests\Feature\Api\V1\Notifications;

use App\Models\User;
use App\Models\UserNotification;
use App\Support\Notifications\UserNotifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_endpoints_require_authentication(): void
    {
        $this->postJson('/api/v1/devices')->assertUnauthorized();
        $this->getJson('/api/v1/notifications')->assertUnauthorized();
    }

    public function test_device_token_is_registered_without_exposure_and_revoked_by_owner(): void
    {
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($u);
        $id = $this->postJson('/api/v1/devices', ['platform' => 'android', 'push_token' => 'secret-provider-token', 'device_name' => 'Pixel'])->assertCreated()->assertJsonMissingPath('data.device.push_token')->json('data.device.id');
        $this->assertDatabaseHas('user_devices', ['user_id' => $u->id, 'token_hash' => hash('sha256', 'secret-provider-token')]);
        $this->deleteJson("/api/v1/devices/$id")->assertOk();
        $this->assertNotNull($u->devices()->first()->revoked_at);
    }

    public function test_preferences_have_safe_defaults_and_support_partial_updates(): void
    {
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($u);
        $this->getJson('/api/v1/notification-preferences')->assertJsonPath('data.preferences.new_messages', true)->assertJsonPath('data.preferences.marketing', false);
        $this->putJson('/api/v1/notification-preferences', ['new_messages' => false])->assertOk()->assertJsonPath('data.preferences.new_messages', false)->assertJsonPath('data.preferences.new_matches', true);
    }

    public function test_push_and_email_preferences_are_independent_and_safety_is_locked(): void
    {
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($u);
        $this->getJson('/api/v1/notification-preferences')
            ->assertJsonPath('data.preferences.push.private_photos', true)
            ->assertJsonPath('data.preferences.email.private_photos', false)
            ->assertJsonPath('data.preferences.push.safety', true)
            ->assertJsonPath('data.preferences.email.safety', true);
        $this->putJson('/api/v1/notification-preferences', ['push' => ['private_photos' => false, 'marketing' => true], 'email' => ['private_photos' => true]])
            ->assertOk()->assertJsonPath('data.preferences.push.private_photos', false)->assertJsonPath('data.preferences.email.private_photos', true)
            ->assertJsonPath('data.preferences.push.marketing', true)->assertJsonPath('data.preferences.marketing', true)
            ->assertJsonPath('data.preferences.marketing_consented_at', fn ($value) => is_string($value));
        $this->putJson('/api/v1/notification-preferences', ['push' => ['safety' => false]])->assertUnprocessable();
    }

    public function test_notifier_keeps_in_app_delivery_and_deduplicates_retries(): void
    {
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $u->notificationPreference()->create(['new_messages' => false, 'email_new_messages' => true]);
        $notifier = app(UserNotifier::class);
        $first = $notifier->send($u->id, 'new_message', ['message_id' => 'message-1'], 'new_messages', 'message-1');
        $second = $notifier->send($u->id, 'new_message', ['message_id' => 'message-1'], 'new_messages', 'message-1');
        $this->assertTrue($first->is($second));
        $this->assertSame(['in_app', 'email'], $first->delivery_channels);
        $this->assertDatabaseCount('user_notifications', 1);
        $safety = $notifier->send($u->id, 'safety_alert', [], 'safety', 'safety-1');
        $this->assertSame(['in_app', 'push', 'email'], $safety->delivery_channels);
    }

    public function test_notification_feed_is_private_cursor_based_and_read_is_idempotent(): void
    {
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $other = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $n = UserNotification::query()->create(['user_id' => $u->id, 'type' => 'new_match', 'data' => ['match_id' => 'match-1']]);
        Sanctum::actingAs($other);
        $this->postJson("/api/v1/notifications/{$n->public_id}/read")->assertNotFound();
        Sanctum::actingAs($u);
        $this->getJson('/api/v1/notifications')->assertJsonPath('data.notifications.0.id', $n->public_id)->assertJsonPath('data.notifications.0.delivery_channels.0', 'in_app');
        $first = $this->postJson("/api/v1/notifications/{$n->public_id}/read")->assertOk()->json('data.read_at');
        $this->postJson("/api/v1/notifications/{$n->public_id}/read")->assertJsonPath('data.read_at', $first);
    }
}
