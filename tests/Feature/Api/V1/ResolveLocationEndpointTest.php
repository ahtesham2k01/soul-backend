<?php

namespace Tests\Feature\Api\V1;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;
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
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'data.location',
                null,
            )
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

        $this->assertStandardValidationError(
            response: $response,
            fields: [
                'latitude',
            ],
        );
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

        $this->assertStandardValidationError(
            response: $response,
            fields: [
                'longitude',
            ],
        );
    }

    public function test_missing_coordinates_are_rejected(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve',
            [],
        );

        $this->assertStandardValidationError(
            response: $response,
            fields: [
                'latitude',
                'longitude',
            ],
        );
    }

    public function test_query_string_coordinates_are_not_accepted(): void
    {
        $response = $this->postJson(
            '/api/v1/location/resolve'
            .'?latitude=30.1575&longitude=71.5249',
            [],
        );

        $this->assertStandardValidationError(
            response: $response,
            fields: [
                'latitude',
                'longitude',
            ],
        );
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
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                true,
            )
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

    public function test_configured_google_coordinate_driver_resolves_real_city_contract(): void
    {
        config([
            'soul.location.driver' => 'none',
            'soul.location.coordinate_driver' => 'google',
            'soul.location.google_geocoding.api_key' => 'test-geocoding-key',
        ]);

        Http::fake([
            'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
                'status' => 'OK',
                'results' => [[
                    'address_components' => [
                        [
                            'long_name' => 'Karachi',
                            'short_name' => 'Karachi',
                            'types' => ['locality', 'political'],
                        ],
                        [
                            'long_name' => 'Sindh',
                            'short_name' => 'SD',
                            'types' => ['administrative_area_level_1', 'political'],
                        ],
                        [
                            'long_name' => 'Pakistan',
                            'short_name' => 'PK',
                            'types' => ['country', 'political'],
                        ],
                    ],
                ]],
            ]),
        ]);

        $this->postJson('/api/v1/location/resolve', [
            'latitude' => 24.8607,
            'longitude' => 67.0011,
            'accuracy_meters' => 12,
        ])->assertOk()
            ->assertJsonPath('data.location.city', 'Karachi')
            ->assertJsonPath('data.location.region', 'Sindh')
            ->assertJsonPath('data.location.country', 'Pakistan')
            ->assertJsonPath('data.location.country_code', 'PK')
            ->assertJsonPath('data.location.source', 'gps')
            ->assertJsonPath('data.location.is_approximate', false)
            ->assertJsonPath('data.location_status', 'resolved');

        Http::assertSentCount(1);
    }


    /**
     * @param array<int, string> $fields
     */
    private function assertStandardValidationError(
        TestResponse $response,
        array $fields,
    ): void {
        $requestId = $response->headers->get(
            'X-Request-ID',
        );

        $response
            ->assertUnprocessable()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'VALIDATION_ERROR',
            )
            ->assertJsonPath(
                'error.message',
                'The submitted data is invalid.',
            )
            ->assertJsonPath(
                'meta.request_id',
                $requestId,
            );

        $this->assertNotNull(
            $requestId,
        );

        foreach ($fields as $field) {
            $errors = $response->json(
                "error.details.fields.{$field}",
            );

            $this->assertIsArray(
                $errors,
                "Validation errors for [{$field}] must be an array.",
            );

            $this->assertNotEmpty(
                $errors,
                "Validation errors for [{$field}] must not be empty.",
            );

            $this->assertIsString(
                $errors[0],
                "The first validation error for [{$field}] must be a string.",
            );
        }
    }
}
