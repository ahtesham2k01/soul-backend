<?php

use App\Http\Controllers\Api\V1\HealthController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class)
        ->name('api.v1.health');

    Route::fallback(fn () => ApiResponse::error(
        code: 'route_not_found',
        message: 'The requested API endpoint does not exist.',
        status: 404,
    ));
});
