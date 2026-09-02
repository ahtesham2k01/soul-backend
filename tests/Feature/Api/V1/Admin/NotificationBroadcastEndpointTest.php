<?php
namespace Tests\Feature\Api\V1\Admin;
use App\Jobs\DeliverNotificationBroadcast;
use App\Models\NotificationBroadcast;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationBroadcastEndpointTest extends TestCase {
 use RefreshDatabase;
 public function test_moderator_cannot_manage_broadcasts(): void { Sanctum::actingAs($this->admin('moderator')); $this->getJson('/api/v1/admin/notification-broadcasts')->assertForbidden(); $this->postJson('/api/v1/admin/notification-broadcasts',[])->assertForbidden(); }
 public function test_super_admin_creates_draft_with_preference_aware_estimate(): void {
  $actor=$this->admin('super_admin'); $enabled=User::factory()->create(['status'=>User::STATUS_ACTIVE]); $disabled=User::factory()->create(['status'=>User::STATUS_ACTIVE]);
  $enabled->notificationPreference()->create(['marketing'=>true]); $disabled->notificationPreference()->create(['marketing'=>false]); Sanctum::actingAs($actor);
  $this->postJson('/api/v1/admin/notification-broadcasts',$this->payload())->assertCreated()->assertJsonPath('data.broadcast.status','draft')->assertJsonPath('data.broadcast.estimated_recipients',1);
  $this->assertDatabaseHas('admin_audit_logs',['action'=>'notification_broadcast.created','admin_user_id'=>$actor->id]);
 }
 public function test_send_requires_explicit_confirmation_and_is_idempotent(): void {
  Queue::fake(); Sanctum::actingAs($this->admin('super_admin')); $id=$this->postJson('/api/v1/admin/notification-broadcasts',$this->payload(['category'=>'safety']))->json('data.broadcast.id');
  $this->postJson("/api/v1/admin/notification-broadcasts/$id/send",['confirmation'=>'NO','reason'=>'Not confirmed'])->assertUnprocessable();
  $body=['confirmation'=>'SEND','reason'=>'Approved safety communication'];
  $this->postJson("/api/v1/admin/notification-broadcasts/$id/send",$body)->assertOk()->assertJsonPath('data.broadcast.status','queued');
  $this->postJson("/api/v1/admin/notification-broadcasts/$id/send",$body)->assertConflict()->assertJsonPath('error.code','BROADCAST_ALREADY_SENT');
  Queue::assertPushed(DeliverNotificationBroadcast::class,1);
 }
 public function test_delivery_job_fans_out_once_and_read_analytics_are_idempotent(): void {
  $actor=$this->admin('super_admin'); $user=User::factory()->create(['status'=>User::STATUS_ACTIVE]); $user->notificationPreference()->create(['safety_updates'=>true]);
  $broadcast=NotificationBroadcast::create(['created_by_admin_id'=>$actor->id,'title'=>'Safety','body'=>'Stay safe','category'=>'safety','audience_type'=>'all_active','status'=>'queued']);
  $job=new DeliverNotificationBroadcast($broadcast->id); $job->handle(); $broadcast->update(['status'=>'queued']); $job->handle();
  $this->assertDatabaseCount('user_notifications',1); $this->assertSame(1,$broadcast->refresh()->delivered_count);
  Sanctum::actingAs($user); $notification=$user->notifications()->firstOrFail(); $this->postJson("/api/v1/notifications/$notification->public_id/read")->assertOk(); $this->postJson("/api/v1/notifications/$notification->public_id/read")->assertOk();
  $this->assertSame(1,$broadcast->refresh()->read_count);
 }
 private function payload(array $overrides=[]): array { return array_merge(['title'=>'Product news','body'=>'A useful SOUL update','category'=>'marketing','audience_type'=>'all_active','audience_value'=>null,'reason'=>'Approved member communication'],$overrides); }
 private function admin(string $role): User { $user=User::factory()->create(['status'=>User::STATUS_ACTIVE]);$user->forceFill(['admin_role'=>$role])->save();return $user; }
}
