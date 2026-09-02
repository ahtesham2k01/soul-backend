<?php
namespace Tests\Feature\Api\V1\Notifications;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
class NotificationEndpointTest extends TestCase {
 use RefreshDatabase;
 public function test_endpoints_require_authentication(): void { $this->postJson('/api/v1/devices')->assertUnauthorized(); $this->getJson('/api/v1/notifications')->assertUnauthorized(); }
 public function test_device_token_is_registered_without_exposure_and_revoked_by_owner(): void {
  $u=User::factory()->create(['status'=>User::STATUS_ACTIVE]); Sanctum::actingAs($u);
  $id=$this->postJson('/api/v1/devices',['platform'=>'android','push_token'=>'secret-provider-token','device_name'=>'Pixel'])->assertCreated()->assertJsonMissingPath('data.device.push_token')->json('data.device.id');
  $this->assertDatabaseHas('user_devices',['user_id'=>$u->id,'token_hash'=>hash('sha256','secret-provider-token')]);
  $this->deleteJson("/api/v1/devices/$id")->assertOk(); $this->assertNotNull($u->devices()->first()->revoked_at);
 }
 public function test_preferences_have_safe_defaults_and_support_partial_updates(): void {
  $u=User::factory()->create(['status'=>User::STATUS_ACTIVE]); Sanctum::actingAs($u);
  $this->getJson('/api/v1/notification-preferences')->assertJsonPath('data.preferences.new_messages',true)->assertJsonPath('data.preferences.marketing',false);
  $this->putJson('/api/v1/notification-preferences',['new_messages'=>false])->assertOk()->assertJsonPath('data.preferences.new_messages',false)->assertJsonPath('data.preferences.new_matches',true);
 }
 public function test_notification_feed_is_private_cursor_based_and_read_is_idempotent(): void {
  $u=User::factory()->create(['status'=>User::STATUS_ACTIVE]); $other=User::factory()->create(['status'=>User::STATUS_ACTIVE]);
  $n=UserNotification::query()->create(['user_id'=>$u->id,'type'=>'new_match','data'=>['match_id'=>'match-1']]);
  Sanctum::actingAs($other); $this->postJson("/api/v1/notifications/{$n->public_id}/read")->assertNotFound();
  Sanctum::actingAs($u); $this->getJson('/api/v1/notifications')->assertJsonPath('data.notifications.0.id',$n->public_id);
  $first=$this->postJson("/api/v1/notifications/{$n->public_id}/read")->assertOk()->json('data.read_at');
  $this->postJson("/api/v1/notifications/{$n->public_id}/read")->assertJsonPath('data.read_at',$first);
 }
}
