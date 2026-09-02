<?php
namespace App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\ProfileVerificationCase;
use App\Models\User;
use App\Models\UserReport;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
class ModerationController extends Controller {
 public function dashboard(Request $r): JsonResponse { return ApiResponse::success(['actor'=>['id'=>$r->user()->public_id,'email'=>$r->user()->email,'role'=>$r->user()->admin_role],'counts'=>['pending_reports'=>UserReport::where('status','pending')->count(),'pending_verifications'=>ProfileVerificationCase::whereIn('status',['pending','under_review'])->count(),'pending_appeals'=>ProfileVerificationCase::where('status','appeal_pending')->count(),'active_users'=>User::where('status',User::STATUS_ACTIVE)->count()]]); }
 public function reports(): JsonResponse { $p=UserReport::where('status','pending')->latest('id')->cursorPaginate(30); return ApiResponse::success(['reports'=>collect($p->items())->map(fn($x)=>['id'=>$x->public_id,'category'=>$x->category,'details'=>$x->details,'created_at'=>$x->created_at->toIso8601String()])->values(),'next_cursor'=>$p->nextCursor()?->encode()]); }
 public function decideReport(Request $r,string $report): JsonResponse { $v=$r->validate(['decision'=>['required',Rule::in(['resolved','dismissed'])],'reason'=>['required','string','max:1000']]); $record=UserReport::where('public_id',$report)->first(); if(!$record)return ApiResponse::error('REPORT_NOT_FOUND','Report not found.',404); $this->auditUpdate($r,$record,'report.'.$v['decision'],['status'=>$v['decision']],$v['reason']); return ApiResponse::success(['id'=>$record->public_id,'status'=>$record->status]); }
 public function verifications(): JsonResponse { $p=ProfileVerificationCase::whereIn('status',['pending','under_review','appeal_pending'])->latest('id')->cursorPaginate(30); return ApiResponse::success(['cases'=>collect($p->items())->map(fn($x)=>['id'=>$x->public_id,'type'=>$x->type,'status'=>$x->status,'submitted_at'=>$x->submitted_at->toIso8601String()])->values(),'next_cursor'=>$p->nextCursor()?->encode()]); }
 public function decideVerification(Request $r,string $case): JsonResponse { $v=$r->validate(['decision'=>['required',Rule::in(['approved','rejected','appeal_available'])],'reason'=>['nullable','required_unless:decision,approved','string','max:1000']]); $record=ProfileVerificationCase::where('public_id',$case)->first(); if(!$record)return ApiResponse::error('VERIFICATION_CASE_NOT_FOUND','Verification case not found.',404); $this->auditUpdate($r,$record,'verification.'.$v['decision'],['status'=>$v['decision'],'reason'=>$v['reason']??null,'reviewed_at'=>now()],$v['reason']??null); return ApiResponse::success(['id'=>$record->public_id,'status'=>$record->status]); }
 private function auditUpdate(Request $r,$record,string $action,array $changes,?string $reason): void { DB::transaction(function()use($r,$record,$action,$changes,$reason){ $before=$record->only(array_keys($changes)); $record->update($changes); AdminAuditLog::create(['admin_user_id'=>$r->user()->id,'action'=>$action,'subject_type'=>$record::class,'subject_id'=>$record->id,'before'=>$before,'after'=>$record->only(array_keys($changes)),'reason'=>$reason,'ip_address'=>$r->ip()]); }); }
}
