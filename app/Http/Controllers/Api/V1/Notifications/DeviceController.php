<?php
namespace App\Http\Controllers\Api\V1\Notifications;
use App\Http\Controllers\Controller;
use App\Models\UserDevice;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
class DeviceController extends Controller {
 public function store(Request $r): JsonResponse { $v=$r->validate(['platform'=>['required','in:ios,android'],'push_token'=>['required','string','max:4096'],'device_name'=>['nullable','string','max:120']]); $hash=hash('sha256',$v['push_token']); $device=UserDevice::query()->where('token_hash',$hash)->first(); if($device&&$device->user_id!==$r->user()->id) $device->delete(); $device=$r->user()->devices()->updateOrCreate(['token_hash'=>$hash],['platform'=>$v['platform'],'push_token'=>$v['push_token'],'device_name'=>$v['device_name']??null,'last_seen_at'=>now(),'revoked_at'=>null]); return ApiResponse::success(['device'=>['id'=>$device->public_id,'platform'=>$device->platform,'device_name'=>$device->device_name]],'Device registered successfully.',201); }
 public function destroy(Request $r,string $device): JsonResponse { $record=$r->user()->devices()->where('public_id',$device)->first(); if(!$record)return ApiResponse::error('DEVICE_NOT_FOUND','Device not found.',404); $record->update(['revoked_at'=>now()]); return ApiResponse::success(['revoked'=>true]); }
}
