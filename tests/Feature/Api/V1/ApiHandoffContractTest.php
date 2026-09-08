<?php

namespace Tests\Feature\Api\V1;

use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class ApiHandoffContractTest extends TestCase
{
    public function test_every_named_v1_api_route_is_present_in_flutter_handoff(): void
    {
        $handoff = File::get(base_path('docs/FLUTTER_API_HANDOFF.md'));
        $routes = collect(Route::getRoutes()->getRoutes())
            ->filter(fn ($route): bool => str_starts_with((string) $route->getName(), 'api.v1.'));

        $this->assertGreaterThanOrEqual(74, $routes->count());

        $routes->each(function ($route) use ($handoff): void {
            $this->assertStringContainsString(
                '`'.$route->getName().'`',
                $handoff,
                'Missing Flutter handoff entry for '.$route->getName(),
            );
            $this->assertStringStartsWith('api/v1/', $route->uri());
        });
    }

    public function test_v1_route_names_are_unique(): void
    {
        $names = collect(Route::getRoutes()->getRoutes())
            ->map(fn ($route): ?string => $route->getName())
            ->filter(fn (?string $name): bool => str_starts_with((string) $name, 'api.v1.'));

        $this->assertCount($names->count(), $names->unique());
    }
}
