<?php

use App\Http\Controllers\Api\V1\AppBootstrapController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\ResolveLocationController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class)
        ->name('api.v1.health');

    Route::get('/bootstrap', AppBootstrapController::class)
        ->name('api.v1.bootstrap');

    Route::post(
        '/location/resolve',
        ResolveLocationController::class,
    )
        ->middleware('throttle:location-resolution')
        ->name('api.v1.location.resolve');

    Route::fallback(fn () => ApiResponse::error(
        code: 'route_not_found',
        message: 'The requested API endpoint does not exist.',
        status: 404,
    ));
});
