<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class RecordRequestTelemetry
{
    public function handle(Request $request, Closure $next): Response
    {
        $startedAt = hrtime(true);
        $response = $next($request);
        $duration = round((hrtime(true) - $startedAt) / 1e6, 2);

        $response->headers->set('Server-Timing', 'app;dur='.$duration);

        Log::info('http_request', [
            'request_id' => $request->attributes->get('request_id'),
            'method' => $request->method(),
            'route' => $request->route()?->getName(),
            'status' => $response->getStatusCode(),
            'duration_ms' => $duration,
            'user_id' => $request->user()?->id,
        ]);

        return $response;
    }
}
