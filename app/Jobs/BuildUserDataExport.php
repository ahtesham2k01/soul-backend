<?php
namespace App\Jobs;
use App\Models\DataExportRequest;
use App\Models\Message;
use App\Models\ProfileDecision;
use App\Models\User;
use App\Models\UserBlock;
use App\Models\UserMatch;
use App\Models\UserReport;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Storage;
class BuildUserDataExport implements ShouldQueue {
 use Queueable;
 public int $tries=3;
 public function __construct(public readonly int $requestId){}
 public function handle():void{$request=DataExportRequest::find($this->requestId);if(!$request||$request->status==='completed')return;$id=$request->user_id;$user=User::with(['profile.intentions','profile.spokenLanguages','religionProfile','privacySetting'])->findOrFail($id);$data=['generated_at'=>now()->toIso8601String(),'account'=>$user->only(['public_id','name','email','phone','preferred_locale','created_at']),'profile'=>$user->profile?->toArray(),'religion'=>$user->religionProfile?->toArray(),'privacy'=>$user->privacySetting?->toArray(),'decisions'=>ProfileDecision::where('actor_user_id',$id)->get()->toArray(),'matches'=>UserMatch::where('first_user_id',$id)->orWhere('second_user_id',$id)->get()->toArray(),'messages'=>Message::where('sender_user_id',$id)->get()->toArray(),'blocks'=>UserBlock::where('blocker_user_id',$id)->get()->toArray(),'reports'=>UserReport::where('reporter_user_id',$id)->get()->toArray()];$path='exports/'.$request->public_id.'.json';Storage::disk(config('soul.privacy.export_disk'))->put($path,json_encode($data,JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR));$request->update(['status'=>'completed','file_path'=>$path,'completed_at'=>now(),'expires_at'=>now()->addDays(7)]);}
}
