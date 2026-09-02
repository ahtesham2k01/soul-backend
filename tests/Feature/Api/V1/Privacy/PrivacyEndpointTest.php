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

class PrivacyEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_age_and_read_receipts_are_always_enabled_while_other_privacy_settings_are_mutable(): void
    {
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $u->privacySetting()->create(['show_age' => false, 'show_city' => true, 'read_receipts' => false, 'discoverable' => true]);
        Sanctum::actingAs($u);
        $this->getJson('/api/v1/privacy/settings')->assertJsonPath('data.privacy.show_age', true)->assertJsonPath('data.privacy.read_receipts', true)->assertJsonPath('data.privacy.discoverable', true);
        $this->putJson('/api/v1/privacy/settings', ['show_age' => false])->assertUnprocessable();
        $this->putJson('/api/v1/privacy/settings', ['read_receipts' => false])->assertUnprocessable();
        $this->putJson('/api/v1/privacy/settings', ['show_city' => false])->assertOk()->assertJsonPath('data.privacy.show_age', true)->assertJsonPath('data.privacy.read_receipts', true)->assertJsonPath('data.privacy.show_city', false);
        $this->assertDatabaseHas('account_privacy_settings', ['user_id' => $u->id, 'show_age' => true, 'read_receipts' => true, 'show_city' => false]);
    }

    public function test_export_request_is_idempotent_and_builds_private_expiring_file(): void
    {
        Storage::fake('local');
        Bus::fake();
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($u)->create();
        Sanctum::actingAs($u);
        $id = $this->postJson('/api/v1/privacy/exports')->assertStatus(202)->json('data.export.id');
        $this->postJson('/api/v1/privacy/exports')->assertJsonPath('data.export.id', $id);
        $this->assertDatabaseCount('data_export_requests', 1);
        $request = DataExportRequest::where('public_id', $id)->firstOrFail();
        (new BuildUserDataExport($request->id))->handle();
        $request->refresh();
        Storage::disk('local')->assertExists($request->file_path);
        $this->getJson('/api/v1/privacy/exports')->assertJsonPath('data.exports.0.download_available', true);
        $this->get('/api/v1/privacy/exports/'.$id.'/download')->assertOk();
    }

    public function test_deletion_requires_exact_confirmation_hides_profile_and_has_thirty_day_recovery(): void
    {
        Bus::fake();
        $u = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($u)->create(['profile_status' => 'live']);
        Sanctum::actingAs($u);
        $this->postJson('/api/v1/privacy/deletion', ['confirmation' => 'delete'])->assertUnprocessable();
        $response = $this->postJson('/api/v1/privacy/deletion', ['confirmation' => 'DELETE MY ACCOUNT'])->assertStatus(202)->assertJsonPath('data.deletion.status', 'scheduled')->assertJsonPath('message', 'Account deletion scheduled with a 30-day recovery period.');
        $scheduledAt = $u->deletionRequests()->latest('id')->firstOrFail()->scheduled_for;
        $this->assertTrue($scheduledAt->between(now()->addDays(30)->subMinute(), now()->addDays(30)->addMinute()));
        $this->assertSame('deletion_scheduled', $u->refresh()->status);
        $this->assertSame('paused_verification', $profile->refresh()->profile_status->value);
        Bus::assertDispatched(DeleteScheduledAccount::class);
        $this->deleteJson('/api/v1/privacy/deletion')->assertOk()->assertJsonPath('data.deletion.status', 'cancelled');
        $this->assertSame(User::STATUS_ACTIVE, $u->refresh()->status);
        $this->assertSame('live', $profile->refresh()->profile_status->value);
    }

    public function test_deletion_job_only_deletes_due_confirmed_account(): void
    {
        $u = User::factory()->create();
        $request = $u->deletionRequests()->create(['status' => 'scheduled', 'scheduled_for' => now()->addDay()]);
        (new DeleteScheduledAccount($request->id))->handle();
        $this->assertModelExists($u);
        $request->update(['scheduled_for' => now()->subMinute()]);
        (new DeleteScheduledAccount($request->id))->handle();
        $this->assertModelMissing($u);
    }
}
