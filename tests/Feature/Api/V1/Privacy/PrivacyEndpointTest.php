<?php
namespace Tests\Feature\Api\V1\Privacy;
use App\Jobs\BuildUserDataExport;
use App\Jobs\DeleteScheduledAccount;
use App\Models\DataExportRequest;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
class PrivacyEndpointTest extends TestCase {
 use RefreshDatabase;
 public function test_privacy_settings_have_defaults_and_partial_updates():void{$u=User::factory()->create(['status'=>User::STATUS_ACTIVE]);Sanctum::actingAs($u);$this->getJson('/api/v1/privacy/settings')->assertJsonPath('data.privacy.show_age',true)->assertJsonPath('data.privacy.discoverable',true);$this->putJson('/api/v1/privacy/settings',['show_age'=>false])->assertOk()->assertJsonPath('data.privacy.show_age',false)->assertJsonPath('data.privacy.show_city',true);}
 public function test_export_request_is_idempotent_and_builds_private_expiring_file():void{Storage::fake('local');Bus::fake();$u=User::factory()->create(['status'=>User::STATUS_ACTIVE]);UserProfile::factory()->for($u)->create();Sanctum::actingAs($u);$id=$this->postJson('/api/v1/privacy/exports')->assertStatus(202)->json('data.export.id');$this->postJson('/api/v1/privacy/exports')->assertJsonPath('data.export.id',$id);$this->assertDatabaseCount('data_export_requests',1);$request=DataExportRequest::where('public_id',$id)->firstOrFail();(new BuildUserDataExport($request->id))->handle();$request->refresh();Storage::disk('local')->assertExists($request->file_path);$this->getJson('/api/v1/privacy/exports')->assertJsonPath('data.exports.0.download_available',true);$this->get('/api/v1/privacy/exports/'.$id.'/download')->assertOk();}
 public function test_deletion_requires_exact_confirmation_hides_profile_and_can_be_cancelled():void{Bus::fake();$u=User::factory()->create(['status'=>User::STATUS_ACTIVE]);$profile=UserProfile::factory()->for($u)->create(['profile_status'=>'live']);Sanctum::actingAs($u);$this->postJson('/api/v1/privacy/deletion',['confirmation'=>'delete'])->assertUnprocessable();$this->postJson('/api/v1/privacy/deletion',['confirmation'=>'DELETE MY ACCOUNT'])->assertStatus(202)->assertJsonPath('data.deletion.status','scheduled');$this->assertSame('deletion_scheduled',$u->refresh()->status);$this->assertSame('paused_verification',$profile->refresh()->profile_status->value);Bus::assertDispatched(DeleteScheduledAccount::class);$this->deleteJson('/api/v1/privacy/deletion')->assertOk()->assertJsonPath('data.deletion.status','cancelled');$this->assertSame(User::STATUS_ACTIVE,$u->refresh()->status);$this->assertSame('live',$profile->refresh()->profile_status->value);}
 public function test_deletion_job_only_deletes_due_confirmed_account():void{$u=User::factory()->create();$request=$u->deletionRequests()->create(['status'=>'scheduled','scheduled_for'=>now()->addDay()]);(new DeleteScheduledAccount($request->id))->handle();$this->assertModelExists($u);$request->update(['scheduled_for'=>now()->subMinute()]);(new DeleteScheduledAccount($request->id))->handle();$this->assertModelMissing($u);}
}
