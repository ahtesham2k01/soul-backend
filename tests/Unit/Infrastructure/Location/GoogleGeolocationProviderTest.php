<?php

namespace Tests\Unit\Infrastructure\Location;

use App\Infrastructure\Location\GoogleGeolocationProvider;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GoogleGeolocationProviderTest extends TestCase
{
    public function test_missing_api_key_returns_null_without_network_request(): void
    {
        config()->set('soul.location.google_geocoding.api_key', null);
        Http::fake();

        $this->assertNull(
            app(GoogleGeolocationProvider::class)->fromCoordinates(
                latitude: 24.8607,
                longitude: 67.0011,
            ),
        );

        Http::assertNothingSent();
    }

    public function test_coordinates_are_reverse_geocoded_into_normalized_location(): void
    {
        config([
            'soul.location.google_geocoding.api_key' => 'test-key',
            'soul.location.google_geocoding.timeout_seconds' => 4,
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

        $location = app(GoogleGeolocationProvider::class)->fromCoordinates(
            latitude: 24.8607,
            longitude: 67.0011,
        );

        $this->assertNotNull($location);
        $this->assertSame('Karachi', $location->city);
        $this->assertSame('Sindh', $location->region);
        $this->assertSame('Pakistan', $location->country);
        $this->assertSame('PK', $location->countryCode);
        $this->assertSame(24.8607, $location->latitude);
        $this->assertSame(67.0011, $location->longitude);
        $this->assertSame('gps', $location->source);
        $this->assertFalse($location->isApproximate);
    }

    public function test_non_ok_or_incomplete_provider_response_returns_null(): void
    {
        config()->set('soul.location.google_geocoding.api_key', 'test-key');

        Http::fake([
            'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
                'status' => 'ZERO_RESULTS',
                'results' => [],
            ]),
        ]);

        $this->assertNull(
            app(GoogleGeolocationProvider::class)->fromCoordinates(
                latitude: 0,
                longitude: 0,
            ),
        );
    }
}
