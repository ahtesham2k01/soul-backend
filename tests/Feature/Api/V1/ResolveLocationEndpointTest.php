<?php

namespace Tests\Feature\Api\V1;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;
use Tests\TestCase;

class ResolveLocationEndpointTest extends TestCase
{
    public function test_valid_coordinates_are_accepted(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve',
            [
                'latitude' => 30.1575,
                'longitude' => 71.5249,
                'accuracy_meters' => 15,
            ],
        );

        $response
            ->assertOk()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.location', null)
            ->assertJsonPath(
                'data.location_status',
                'unavailable',
            );
    }

    public function test_invalid_latitude_is_rejected(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve',
            [
                'latitude' => 91,
                'longitude' => 71.5249,
            ],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'latitude',
            ]);
    }

    public function test_invalid_longitude_is_rejected(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve',
            [
                'latitude' => 30.1575,
                'longitude' => 181,
            ],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'longitude',
            ]);
    }

    public function test_missing_coordinates_are_rejected(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve',
            [],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'latitude',
                'longitude',
            ]);
    }

    public function test_query_string_coordinates_are_not_accepted(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve'
            .'?latitude=30.1575&longitude=71.5249',
            [],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'latitude',
                'longitude',
            ]);
    }

    public function test_resolved_location_uses_flutter_friendly_contract(): void
    {
        $this->app->instance(
            GeolocationProvider::class,
            new class implements GeolocationProvider
            {
                public function fromCoordinates(
                    float $latitude,
                    float $longitude,
                ): ?LocationData {
                    return new LocationData(
                        city: 'Test City',
                        region: 'Test Region',
                        country: 'Test Country',
                        countryCode: 'TC',
                        latitude: $latitude,
                        longitude: $longitude,
                        timezone: 'Test/Timezone',
                        source: 'gps',
                        isApproximate: false,
                    );
                }

                public function fromIp(
                    string $ipAddress,
                ): ?LocationData {
                    return null;
                }
            },
        );

        $response = $this->postJson(
            '/api/v1/location/resolve',
            [
                'latitude' => 30.1575,
                'longitude' => 71.5249,
                'accuracy_meters' => 15,
            ],
        );

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath(
                'message',
                'Location resolved successfully.',
            )
            ->assertJsonPath(
                'data.location.city',
                'Test City',
            )
            ->assertJsonPath(
                'data.location.region',
                'Test Region',
            )
            ->assertJsonPath(
                'data.location.country',
                'Test Country',
            )
            ->assertJsonPath(
                'data.location.country_code',
                'TC',
            )
            ->assertJsonPath(
                'data.location.timezone',
                'Test/Timezone',
            )
            ->assertJsonPath(
                'data.location.source',
                'gps',
            )
            ->assertJsonPath(
                'data.location.is_approximate',
                false,
            )
            ->assertJsonPath(
                'data.location_status',
                'resolved',
            );
    }

    public function test_location_endpoint_is_rate_limited(): void
    {
        for ($attempt = 1; $attempt <= 10; $attempt++) {
            $this->postJson(
                '/api/v1/location/resolve',
                [
                    'latitude' => 30.1575,
                    'longitude' => 71.5249,
                ],
            )->assertOk();
        }

        $this->postJson(
            '/api/v1/location/resolve',
            [
                'latitude' => 30.1575,
                'longitude' => 71.5249,
            ],
        )->assertTooManyRequests();
    }
}
