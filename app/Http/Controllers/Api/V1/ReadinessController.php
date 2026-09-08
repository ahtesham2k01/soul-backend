<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Throwable;

class ReadinessController extends Controller
{
    public function __invoke(): JsonResponse
    {
        try {
            DB::select('select 1');
            Cache::put('health:readiness', now()->timestamp, 10);

            if (! Cache::get('health:readiness')) {
                throw new RuntimeException('Cache unavailable.');
            }

            return ApiResponse::success(
                data: [
                    'status' => 'ready',
                    'checks' => [
                        'database' => 'ok',
                        'cache' => 'ok',
                    ],
                    'timestamp' => now()->toIso8601String(),
                ],
                message: 'SOUL API is ready.',
            );
        } catch (Throwable) {
            return ApiResponse::error(
                code: 'SERVICE_NOT_READY',
                message: 'A required service is unavailable.',
                status: 503,
            );
        }
    }
}
