<?php
namespace App\Jobs;
use App\Models\NotificationBroadcast;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class DeliverNotificationBroadcast implements ShouldQueue {
 use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
 public int $tries=5; public array $backoff=[60,300,900,3600];
 public function __construct(public int $broadcastId) {}
 public function handle(): void {
  $broadcast=NotificationBroadcast::find($this->broadcastId); if(!$broadcast||!in_array($broadcast->status,['queued','processing'],true))return;
  $broadcast->update(['status'=>'processing']);
  $query=User::query()->where('status',User::STATUS_ACTIVE)->whereNull('admin_role');
  if($broadcast->audience_type==='country')$query->whereHas('profile',fn($q)=>$q->where('country_code',strtoupper($broadcast->audience_value)));
  if($broadcast->audience_type==='locale')$query->where('preferred_locale',$broadcast->audience_value);
  $preference=$broadcast->category==='marketing'?'marketing':'safety_updates';
  $query->where(function($q)use($preference){$q->whereDoesntHave('notificationPreference')->orWhereHas('notificationPreference',fn($p)=>$p->where($preference,true));});
  $query->select('id')->chunkById(500,function($users)use($broadcast){
   $now=now(); DB::table('user_notifications')->insertOrIgnore($users->map(fn($user)=>['public_id'=>(string)Str::ulid(),'broadcast_id'=>$broadcast->id,'user_id'=>$user->id,'type'=>'broadcast','data'=>json_encode(['title'=>$broadcast->title,'body'=>$broadcast->body,'category'=>$broadcast->category],JSON_THROW_ON_ERROR),'created_at'=>$now,'updated_at'=>$now])->all());
  });
  $delivered=DB::table('user_notifications')->where('broadcast_id',$broadcast->id)->count();
  $broadcast->update(['status'=>'completed','delivered_count'=>$delivered,'completed_at'=>now()]);
 }
}
