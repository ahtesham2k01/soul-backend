<?php

use App\Http\Controllers\Api\V1\AppBootstrapController;
use App\Http\Controllers\Api\V1\Auth\CurrentUserController;
use App\Http\Controllers\Api\V1\Auth\GoogleSignInController;
use App\Http\Controllers\Api\V1\Auth\LoginRequestOtpController;
use App\Http\Controllers\Api\V1\Auth\LoginVerifyOtpController;
use App\Http\Controllers\Api\V1\Auth\LogoutAllDevicesController;
use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\RegisterRequestOtpController;
use App\Http\Controllers\Api\V1\Auth\RegisterVerifyOtpController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\ResolveLocationController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get(
        '/health',
        HealthController::class,
    )->name('api.v1.health');

    Route::get(
        '/bootstrap',
        AppBootstrapController::class,
    )->name('api.v1.bootstrap');

    Route::post(
        '/auth/register/request-otp',
        RegisterRequestOtpController::class,
    )
        ->middleware('throttle:email-otp-request')
        ->name('api.v1.auth.register.request-otp');

    Route::post(
        '/auth/register/verify-otp',
        RegisterVerifyOtpController::class,
    )
        ->middleware('throttle:email-otp-verification')
        ->name('api.v1.auth.register.verify-otp');

    Route::post(
        '/auth/login/request-otp',
        LoginRequestOtpController::class,
    )
        ->middleware('throttle:email-otp-request')
        ->name('api.v1.auth.login.request-otp');

    Route::post(
        '/auth/login/verify-otp',
        LoginVerifyOtpController::class,
    )
        ->middleware('throttle:email-otp-verification')
        ->name('api.v1.auth.login.verify-otp');

    Route::post(
        '/auth/google',
        GoogleSignInController::class,
    )
        ->middleware('throttle:social-sign-in')
        ->name('api.v1.auth.google');

    Route::middleware([
        'auth:sanctum',
        'active.account',
    ])
        ->prefix('auth')
        ->group(function (): void {
            Route::get(
                '/me',
                CurrentUserController::class,
            )->name('api.v1.auth.me');

            Route::post(
                '/logout',
                LogoutController::class,
            )->name('api.v1.auth.logout');

            Route::post(
                '/logout-all',
                LogoutAllDevicesController::class,
            )->name('api.v1.auth.logout-all');
        });

    Route::post(
        '/location/resolve',
        ResolveLocationController::class,
    )
        ->middleware('throttle:location-resolution')
        ->name('api.v1.location.resolve');

    Route::fallback(
        fn () => ApiResponse::error(
            code: 'route_not_found',
            message: 'The requested API endpoint does not exist.',
            status: 404,
        ),
    );
});
