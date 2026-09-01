<?php
namespace App\Jobs;
use App\Models\AccountDeletionRequest;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Storage;
class DeleteScheduledAccount implements ShouldQueue {
 use Queueable;
 public function __construct(public readonly int $requestId){}
 public function handle():void{$request=AccountDeletionRequest::find($this->requestId);if(!$request||$request->status!=='scheduled'||$request->scheduled_for->isFuture())return;$user=\App\Models\User::find($request->user_id);if(!$user)return;foreach($user->dataExportRequests as $export){if($export->file_path)Storage::disk('local')->delete($export->file_path);}$user->tokens()->delete();$user->delete();}
}
