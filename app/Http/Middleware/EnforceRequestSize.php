<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class EnforceRequestSize
{
    public function handle(Request $request, Closure $next): Response
    {
        $contentLength = $request->headers->get('Content-Length');
        if ($contentLength === null || ! ctype_digit($contentLength)) {
            return $next($request);
        }

        $maximumBytes = $request->isMethodSafe()
            ? 0
            : ($this->isMultipart($request)
                ? max(1, (int) config('soul.security.maximum_multipart_request_kilobytes', 6144)) * 1024
                : max(1, (int) config('soul.security.maximum_json_request_kilobytes', 256)) * 1024);

        if ($maximumBytes > 0 && (int) $contentLength > $maximumBytes) {
            return ApiResponse::error(
                code: 'REQUEST_TOO_LARGE',
                message: 'The request body is too large.',
                status: JsonResponse::HTTP_REQUEST_ENTITY_TOO_LARGE,
            );
        }

        return $next($request);
    }

    private function isMultipart(Request $request): bool
    {
        return str_starts_with(strtolower((string) $request->header('Content-Type')), 'multipart/form-data');
    }
}
