<?php

namespace App\Providers;

use App\Contracts\Location\GeolocationProvider;
use App\Infrastructure\Location\CloudflareGeolocationProvider;
use App\Infrastructure\Location\NullGeolocationProvider;
use App\Services\Auth\EmailOtpService;
use App\Support\ApiResponse;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use InvalidArgumentException;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(
            GeolocationProvider::class,
            function ($app): GeolocationProvider {
                $driver = config(
                    'soul.location.driver',
                    'none',
                );

                return match ($driver) {
                    'none' => $app->make(
                        NullGeolocationProvider::class,
                    ),

                    'cloudflare' => $app->make(
                        CloudflareGeolocationProvider::class,
                    ),

                    default => throw new InvalidArgumentException(
                        "Unsupported geolocation driver [{$driver}].",
                    ),
                };
            },
        );
    }

    public function boot(): void
    {
        $this->configureLocationRateLimiter();
        $this->configureEmailOtpRateLimiter();
        $this->configureEmailOtpVerificationRateLimiter();
    }

    private function configureLocationRateLimiter(): void
    {
        RateLimiter::for(
            'location-resolution',
            function (Request $request): array {
                $ipAddress = $request->ip();

                return [
                    Limit::perMinute(10)
                        ->by('location-minute:' . $ipAddress),

                    Limit::perDay(100)
                        ->by('location-day:' . $ipAddress),
                ];
            },
        );
    }

    private function configureEmailOtpRateLimiter(): void
    {
        RateLimiter::for(
            'email-otp-request',
            function (Request $request): array {
                $ipAddress = $request->ip();

                $emailOtpService = app(
                    EmailOtpService::class,
                );

                $normalizedEmail = $emailOtpService->normalizeEmail(
                    (string) $request->input('email', ''),
                );

                $emailHash = $normalizedEmail === ''
                    ? 'missing'
                    : $emailOtpService->hashEmail(
                        $normalizedEmail,
                    );

                $rateLimitResponse = static function (
                    Request $request,
                    array $headers,
                ): JsonResponse {
                    return ApiResponse::error(
                        code: 'RATE_LIMIT_EXCEEDED',
                        message: 'Too many verification code requests. Please try again later.',
                        status: 429,
                        details: [
                            'retry_after_seconds' => (int) (
                                $headers['Retry-After'] ?? 60
                            ),
                        ],
                    )->withHeaders($headers);
                };

                return [
                    Limit::perMinute(1)
                        ->by('otp-email-minute:' . $emailHash)
                        ->response($rateLimitResponse),

                    Limit::perHour(5)
                        ->by('otp-email-hour:' . $emailHash)
                        ->response($rateLimitResponse),

                    Limit::perMinute(10)
                        ->by('otp-ip-minute:' . $ipAddress)
                        ->response($rateLimitResponse),

                    Limit::perDay(50)
                        ->by('otp-ip-day:' . $ipAddress)
                        ->response($rateLimitResponse),
                ];
            },
        );
    }

    private function configureEmailOtpVerificationRateLimiter(): void
    {
        RateLimiter::for(
            'email-otp-verification',
            function (Request $request): array {
                $ipAddress = $request->ip();

                $verificationId = (string) $request->input(
                    'verification_id',
                    'missing',
                );

                $rateLimitResponse = static function (
                    Request $request,
                    array $headers,
                ): JsonResponse {
                    return ApiResponse::error(
                        code: 'RATE_LIMIT_EXCEEDED',
                        message: 'Too many verification attempts. Please try again later.',
                        status: 429,
                        details: [
                            'retry_after_seconds' => (int) (
                                $headers['Retry-After'] ?? 60
                            ),
                        ],
                    )->withHeaders($headers);
                };

                return [
                    Limit::perMinute(10)
                        ->by(
                            'otp-verification-id:'
                                . $verificationId,
                        )
                        ->response($rateLimitResponse),

                    Limit::perMinute(30)
                        ->by(
                            'otp-verification-ip-minute:'
                                . $ipAddress,
                        )
                        ->response($rateLimitResponse),

                    Limit::perDay(200)
                        ->by(
                            'otp-verification-ip-day:'
                                . $ipAddress,
                        )
                        ->response($rateLimitResponse),
                ];
            },
        );
    }
}
