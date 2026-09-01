<?php
namespace Tests\Feature\Api\V1\Admin;
use App\Models\ProfileVerificationCase;
use App\Models\User;
use App\Models\UserReport;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
class AdminModerationEndpointTest extends TestCase {
 use RefreshDatabase;
 public function test_non_admin_is_forbidden(): void { $u=User::factory()->create(['status'=>User::STATUS_ACTIVE]); Sanctum::actingAs($u); $this->getJson('/api/v1/admin/dashboard')->assertForbidden()->assertJsonPath('error.code','ADMIN_ACCESS_DENIED'); }
 public function test_moderator_sees_dashboard_and_pending_report_queue(): void { $admin=$this->admin(); $target=User::factory()->create(); UserReport::create(['reporter_user_id'=>$admin->id,'reported_user_id'=>$target->id,'category'=>'scam','status'=>'pending']); Sanctum::actingAs($admin); $this->getJson('/api/v1/admin/dashboard')->assertJsonPath('data.counts.pending_reports',1); $this->getJson('/api/v1/admin/reports')->assertJsonCount(1,'data.reports'); }
 public function test_report_decision_is_audited(): void { $admin=$this->admin(); $target=User::factory()->create(); $report=UserReport::create(['reporter_user_id'=>$admin->id,'reported_user_id'=>$target->id,'category'=>'scam','status'=>'pending']); Sanctum::actingAs($admin); $this->putJson("/api/v1/admin/reports/{$report->public_id}",['decision'=>'resolved','reason'=>'Evidence confirmed'])->assertOk()->assertJsonPath('data.status','resolved'); $this->assertDatabaseHas('admin_audit_logs',['admin_user_id'=>$admin->id,'action'=>'report.resolved','subject_id'=>$report->id]); }
 public function test_verification_decision_requires_reason_and_is_audited(): void { $admin=$this->admin(); $u=User::factory()->create(); $case=ProfileVerificationCase::create(['user_id'=>$u->id,'type'=>'identity','status'=>'pending','submitted_at'=>now()]); Sanctum::actingAs($admin); $this->putJson("/api/v1/admin/verifications/{$case->public_id}",['decision'=>'rejected'])->assertUnprocessable(); $this->putJson("/api/v1/admin/verifications/{$case->public_id}",['decision'=>'appeal_available','reason'=>'Document mismatch'])->assertOk()->assertJsonPath('data.status','appeal_available'); $this->assertDatabaseHas('admin_audit_logs',['action'=>'verification.appeal_available','subject_id'=>$case->id]); }
 private function admin(): User { $u=User::factory()->create(['status'=>User::STATUS_ACTIVE]); $u->forceFill(['admin_role'=>'moderator'])->save(); return $u; }
}
