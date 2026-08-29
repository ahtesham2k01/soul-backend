<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

final class ApiResponse
{
    public static function success(
        mixed $data = null,
        string $message = 'OK',
        int $status = 200,
        array $meta = [],
    ): JsonResponse {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'meta' => self::withRequestId($meta),
        ], $status);
    }

    public static function error(
        string $code,
        string $message,
        int $status = 400,
        array $details = [],
        array $meta = [],
    ): JsonResponse {
        return response()->json([
            'success' => false,
            'error' => [
                'code' => $code,
                'message' => $message,
                'details' => $details,
            ],
            'meta' => self::withRequestId($meta),
        ], $status);
    }

    private static function withRequestId(array $meta): array
    {
        if (! app()->bound('request_id')) {
            return $meta;
        }

        return array_merge($meta, [
            'request_id' => app('request_id'),
        ]);
    }
}
