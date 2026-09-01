<?php
namespace App\Http\Controllers\Api\V1\Notifications;
use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
class PreferenceController extends Controller {
 public function show(Request $r): JsonResponse { $p=$r->user()->notificationPreference()->firstOrCreate([])->refresh(); return ApiResponse::success(['preferences'=>$p->only(['new_matches','new_messages','safety_updates','marketing'])]); }
 public function update(Request $r): JsonResponse { $v=$r->validate(['new_matches'=>['sometimes','boolean'],'new_messages'=>['sometimes','boolean'],'safety_updates'=>['sometimes','boolean'],'marketing'=>['sometimes','boolean']]); $p=$r->user()->notificationPreference()->firstOrCreate([])->refresh(); $p->update($v); return ApiResponse::success(['preferences'=>$p->fresh()->only(['new_matches','new_messages','safety_updates','marketing'])]); }
}
