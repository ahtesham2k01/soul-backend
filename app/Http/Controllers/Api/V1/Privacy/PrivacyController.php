<?php
namespace App\Http\Controllers\Api\V1\Privacy;
use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Jobs\BuildUserDataExport;
use App\Jobs\DeleteScheduledAccount;
use App\Models\AccountDeletionRequest;
use App\Models\DataExportRequest;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
class PrivacyController extends Controller {
 public function showSettings(Request $r):JsonResponse{$p=$r->user()->privacySetting()->firstOrCreate([])->refresh();return ApiResponse::success(['privacy'=>$p->only(['show_age','show_city','read_receipts','discoverable'])]);}
 public function updateSettings(Request $r):JsonResponse{$v=$r->validate(['show_age'=>['sometimes','boolean'],'show_city'=>['sometimes','boolean'],'read_receipts'=>['sometimes','boolean'],'discoverable'=>['sometimes','boolean']]);$p=$r->user()->privacySetting()->firstOrCreate([])->refresh();$p->update($v);return ApiResponse::success(['privacy'=>$p->fresh()->only(['show_age','show_city','read_receipts','discoverable'])]);}
 public function requestExport(Request $r):JsonResponse{$existing=$r->user()->dataExportRequests()->whereIn('status',['pending','processing'])->latest()->first();$export=$existing??$r->user()->dataExportRequests()->create(['status'=>'pending']);if(!$existing)DB::afterCommit(fn()=>BuildUserDataExport::dispatch($export->id));return ApiResponse::success(['export'=>['id'=>$export->public_id,'status'=>$export->status]],'Data export requested.',202);}
 public function exports(Request $r):JsonResponse{$items=$r->user()->dataExportRequests()->latest('id')->limit(10)->get();return ApiResponse::success(['exports'=>$items->map(fn($x)=>['id'=>$x->public_id,'status'=>$x->status,'completed_at'=>$x->completed_at?->toIso8601String(),'expires_at'=>$x->expires_at?->toIso8601String(),'download_available'=>$x->status==='completed'&&$x->expires_at?->isFuture()])]);}
 public function download(Request $r,string $export){$x=$r->user()->dataExportRequests()->where('public_id',$export)->first();if(!$x||$x->status!=='completed'||!$x->expires_at?->isFuture()||!$x->file_path||!Storage::disk('local')->exists($x->file_path))return ApiResponse::error('EXPORT_NOT_AVAILABLE','Export is not available.',404);return Storage::disk('local')->download($x->file_path,'soul-data-export.json',['Content-Type'=>'application/json']);}
 public function scheduleDeletion(Request $r):JsonResponse{$r->validate(['confirmation'=>['required','in:DELETE MY ACCOUNT']]);$existing=$r->user()->deletionRequests()->where('status','scheduled')->first();if($existing)return ApiResponse::success(['deletion'=>$this->deletion($existing)],'Account deletion already scheduled.',202);$record=DB::transaction(function()use($r){$profile=$r->user()->profile()->lockForUpdate()->first();$record=$r->user()->deletionRequests()->create(['status'=>'scheduled','previous_profile_status'=>$profile?->profile_status?->value,'scheduled_for'=>now()->addDays(7)]);$profile?->update(['profile_status'=>ProfileStatus::PausedVerification]);$r->user()->devices()->update(['revoked_at'=>now()]);$r->user()->forceFill(['status'=>'deletion_scheduled'])->save();DB::afterCommit(fn()=>DeleteScheduledAccount::dispatch($record->id)->delay($record->scheduled_for));return $record;});return ApiResponse::success(['deletion'=>$this->deletion($record)],'Account deletion scheduled.',202);}
 public function deletionStatus(Request $r):JsonResponse{$x=$r->user()->deletionRequests()->latest('id')->first();return ApiResponse::success(['deletion'=>$x?$this->deletion($x):null]);}
 public function cancelDeletion(Request $r):JsonResponse{$x=$r->user()->deletionRequests()->where('status','scheduled')->latest()->first();if(!$x)return ApiResponse::error('DELETION_NOT_SCHEDULED','No deletion is scheduled.',409);DB::transaction(function()use($r,$x){$x->update(['status'=>'cancelled','cancelled_at'=>now()]);$r->user()->forceFill(['status'=>User::STATUS_ACTIVE])->save();if($x->previous_profile_status)$r->user()->profile()->update(['profile_status'=>$x->previous_profile_status]);});return ApiResponse::success(['deletion'=>$this->deletion($x->refresh())],'Account deletion cancelled.');}
 private function deletion(AccountDeletionRequest $x):array{return['id'=>$x->public_id,'status'=>$x->status,'scheduled_for'=>$x->scheduled_for->toIso8601String(),'cancelled_at'=>$x->cancelled_at?->toIso8601String()];}
}
