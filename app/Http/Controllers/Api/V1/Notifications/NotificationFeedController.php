<?php
namespace App\Http\Controllers\Api\V1\Notifications;
use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
class NotificationFeedController extends Controller {
 public function index(Request $r): JsonResponse { $page=$r->user()->notifications()->latest('id')->cursorPaginate(30); return ApiResponse::success(['notifications'=>collect($page->items())->map(fn($n)=>['id'=>$n->public_id,'type'=>$n->type,'data'=>$n->data,'read_at'=>$n->read_at?->toIso8601String(),'created_at'=>$n->created_at->toIso8601String()])->values(),'next_cursor'=>$page->nextCursor()?->encode()]); }
 public function read(Request $r,string $notification): JsonResponse { $n=$r->user()->notifications()->where('public_id',$notification)->first(); if(!$n)return ApiResponse::error('NOTIFICATION_NOT_FOUND','Notification not found.',404); $n->update(['read_at'=>$n->read_at??now()]); return ApiResponse::success(['id'=>$n->public_id,'read_at'=>$n->read_at->toIso8601String()]); }
}
