<?php
namespace App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Controller;
use App\Jobs\DeliverNotificationBroadcast;
use App\Models\AdminAuditLog;
use App\Models\NotificationBroadcast;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class NotificationBroadcastController extends Controller {
 public function index(): JsonResponse {
  $items=NotificationBroadcast::latest('id')->limit(100)->get();
  return ApiResponse::success(['broadcasts'=>$items->map(fn($x)=>$this->serialize($x))->values()]);
 }
 public function store(Request $request): JsonResponse {
  $v=$request->validate(['title'=>['required','string','max:120'],'body'=>['required','string','max:1000'],'category'=>['required',Rule::in(['safety','marketing'])],'audience_type'=>['required',Rule::in(['all_active','country','locale'])],'audience_value'=>['nullable','required_unless:audience_type,all_active','string','max:40'],'reason'=>['required','string','min:5','max:1000']]);
  if($v['audience_type']==='country')$v['audience_value']=strtoupper($v['audience_value']);
  $broadcast=DB::transaction(function()use($request,$v){
   $broadcast=NotificationBroadcast::create([...$v,'created_by_admin_id'=>$request->user()->id,'status'=>'draft','estimated_recipients'=>$this->audience($v)->count()]);
   $this->audit($request,$broadcast,'notification_broadcast.created',null,$v,$v['reason']); return $broadcast;
  });
  return ApiResponse::success(['broadcast'=>$this->serialize($broadcast)],'Broadcast draft created.',201);
 }
 public function send(Request $request,NotificationBroadcast $broadcast): JsonResponse {
  $v=$request->validate(['confirmation'=>['required','in:SEND'],'reason'=>['required','string','min:5','max:1000']]);
  $queued=DB::transaction(function()use($request,$broadcast,$v){
   $locked=NotificationBroadcast::lockForUpdate()->findOrFail($broadcast->id); if($locked->status!=='draft')return false;
   $before=$locked->only(['status']); $locked->update(['status'=>'queued','sent_at'=>now(),'estimated_recipients'=>$this->audience($locked->toArray())->count()]);
   $this->audit($request,$locked,'notification_broadcast.queued',$before,$locked->only(['status','estimated_recipients']),$v['reason']);
   DeliverNotificationBroadcast::dispatch($locked->id)->afterCommit(); return true;
  });
  if(!$queued)return ApiResponse::error('BROADCAST_ALREADY_SENT','Only a draft broadcast can be sent.',409);
  return ApiResponse::success(['broadcast'=>$this->serialize($broadcast->refresh())],'Broadcast queued safely.');
 }
 private function audience(array $broadcast) {
  $q=User::query()->where('status',User::STATUS_ACTIVE)->whereNull('admin_role'); $type=$broadcast['audience_type']; $value=$broadcast['audience_value']??null;
  if($type==='country')$q->whereHas('profile',fn($p)=>$p->where('country_code',strtoupper($value)));
  if($type==='locale')$q->where('preferred_locale',$value);
  $preference=($broadcast['category']??'safety')==='marketing'?'marketing':'safety_updates';
  return $q->where(fn($u)=>$u->whereDoesntHave('notificationPreference')->orWhereHas('notificationPreference',fn($p)=>$p->where($preference,true)));
 }
 private function audit(Request $r,NotificationBroadcast $b,string $action,?array $before,array $after,string $reason): void { AdminAuditLog::create(['admin_user_id'=>$r->user()->id,'action'=>$action,'subject_type'=>NotificationBroadcast::class,'subject_id'=>$b->id,'before'=>$before,'after'=>$after,'reason'=>$reason,'ip_address'=>$r->ip()]); }
 private function serialize(NotificationBroadcast $x): array { return ['id'=>$x->public_id,'title'=>$x->title,'body'=>$x->body,'category'=>$x->category,'audience_type'=>$x->audience_type,'audience_value'=>$x->audience_value,'status'=>$x->status,'estimated_recipients'=>$x->estimated_recipients,'delivered_count'=>$x->delivered_count,'read_count'=>$x->read_count,'sent_at'=>$x->sent_at?->toIso8601String(),'completed_at'=>$x->completed_at?->toIso8601String()]; }
}
