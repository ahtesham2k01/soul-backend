<?php

namespace App\Providers;

use App\Contracts\Location\GeolocationProvider;
use App\Infrastructure\Location\NullGeolocationProvider;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(
            GeolocationProvider::class,
            NullGeolocationProvider::class,
        );
    }

    public function boot(): void
    {
        RateLimiter::for(
            'location-resolution',
            function (Request $request): array {
                $ipAddress = $request->ip();

                return [
                    Limit::perMinute(10)
                        ->by('location-minute:'.$ipAddress),

                    Limit::perDay(100)
                        ->by('location-day:'.$ipAddress),
                ];
            },
        );
    }
}
