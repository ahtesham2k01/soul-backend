<?php

namespace Tests\Feature\Api\V1;

use Tests\TestCase;

class HealthEndpointTest extends TestCase
{
    public function test_health_endpoint_returns_successful_response(): void
    {
        $response = $this->getJson('/api/v1/health');

        $requestId = $response->headers->get('X-Request-ID');

        $response
            ->assertOk()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath('meta.request_id', $requestId)
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'SOUL API is running.')
            ->assertJsonPath('data.status', 'ok')
            ->assertJsonPath('data.api_version', 'v1')
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'status',
                    'api_version',
                    'timestamp',
                ],
                'meta' => [
                    'request_id',
                ],
            ]);
    }

    public function test_unknown_api_endpoint_returns_standard_not_found_response(): void
    {
        $response = $this->getJson('/api/v1/anything');

        $response
            ->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'route_not_found')
            ->assertJsonPath(
                'error.message',
                'The requested API endpoint does not exist.',
            )
            ->assertJsonStructure([
                'success',
                'error' => [
                    'code',
                    'message',
                    'details',
                ],
                'meta',
            ]);
    }
}
