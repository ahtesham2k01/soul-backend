<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class AttachRequestId
{
    public function handle(Request $request, Closure $next): Response
    {
        $incomingRequestId = $request->header('X-Request-ID');

        $requestId = is_string($incomingRequestId)
            && preg_match('/^[A-Za-z0-9._-]{8,100}$/', $incomingRequestId)
                ? $incomingRequestId
                : (string) Str::uuid();

        $request->attributes->set('request_id', $requestId);
        app()->instance('request_id', $requestId);

        $response = $next($request);

        $response->headers->set('X-Request-ID', $requestId);

        return $response;
    }
}
