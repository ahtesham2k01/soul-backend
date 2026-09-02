<?php

use App\Http\Middleware\ApplySecurityHeaders;
use App\Http\Middleware\AttachRequestId;
use App\Http\Middleware\EnsureAccountIsActive;
use App\Http\Middleware\EnsureUserIsAdmin;
use App\Http\Middleware\RecordRequestTelemetry;
use App\Http\Middleware\SetRequestLocale;
use App\Support\ApiResponse;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->statefulApi();

        $middleware->prependToGroup(
            'api',
            [AttachRequestId::class, SetRequestLocale::class],
        );
        $middleware->appendToGroup('api', [
            RecordRequestTelemetry::class,
            ApplySecurityHeaders::class,
        ]);
        $middleware->appendToGroup('web', ApplySecurityHeaders::class);

        $middleware->alias([
            'active.account' => EnsureAccountIsActive::class,
            'admin' => EnsureUserIsAdmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(
            function (
                ValidationException $exception,
                Request $request,
            ): ?JsonResponse {
                if (! $request->is('api/*')) {
                    return null;
                }

                return ApiResponse::validation(
                    errors: $exception->errors(),
                );
            },
        );

        $exceptions->render(
            function (
                AuthenticationException $exception,
                Request $request,
            ): ?JsonResponse {
                if (! $request->is('api/*')) {
                    return null;
                }

                return ApiResponse::error(
                    code: 'UNAUTHENTICATED',
                    message: 'Authentication is required.',
                    status: 401,
                );
            },
        );
    })
    ->create();
