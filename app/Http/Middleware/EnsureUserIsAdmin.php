<?php
namespace App\Http\Middleware;
use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
class EnsureUserIsAdmin {
 public function handle(Request $request,Closure $next,string ...$roles): Response { $role=$request->user()?->admin_role; if($role===null||($roles!==[]&&!in_array($role,$roles,true))) return ApiResponse::error('ADMIN_ACCESS_DENIED','Admin access is required.',403); return $next($request); }
}
