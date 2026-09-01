<?php

namespace Tests\Feature\Api\V1;

use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class MachineReadableApiContractTest extends TestCase
{
    public function test_openapi_contract_matches_every_named_v1_route(): void
    {
        $contract = json_decode(
            File::get(base_path('docs/contracts/openapi-v1.json')),
            true,
            flags: JSON_THROW_ON_ERROR,
        );
        $operations = collect($contract['paths'])->flatMap(function (array $path, string $uri): array {
            return collect($path)->mapWithKeys(fn (array $operation, string $method): array => [
                $operation['operationId'] => [
                    'method' => strtoupper($method),
                    'uri' => 'api/v1'.($uri === '/' ? '' : $uri),
                ],
            ])->all();
        });

        $routes = collect(Route::getRoutes()->getRoutes())
            ->filter(fn ($route): bool => str_starts_with((string) $route->getName(), 'api.v1.'));

        $this->assertCount(67, $operations);
        $this->assertCount($routes->count(), $operations);

        $routes->each(function ($route) use ($operations): void {
            $operation = $operations->get($route->getName());
            $this->assertNotNull($operation, 'Missing OpenAPI operation '.$route->getName());
            $this->assertSame($route->uri(), $operation['uri']);
            $this->assertContains($operation['method'], $route->methods());
        });
    }

    public function test_postman_collection_contains_every_openapi_operation(): void
    {
        $openapi = File::get(base_path('docs/contracts/openapi-v1.json'));
        $postman = File::get(base_path('docs/contracts/postman-v1.collection.json'));
        $operationIds = collect(json_decode($openapi, true, flags: JSON_THROW_ON_ERROR)['paths'])
            ->flatMap(fn (array $path): array => collect($path)->pluck('operationId')->all());

        $operationIds->each(fn (string $operationId) => $this->assertStringContainsString($operationId, $postman));
    }
}
