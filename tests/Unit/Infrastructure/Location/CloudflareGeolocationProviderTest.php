<?php

namespace Tests\Unit\Infrastructure\Location;

use App\Data\LocationData;
use App\Infrastructure\Location\CloudflareGeolocationProvider;
use Illuminate\Http\Request;
use Tests\TestCase;

class CloudflareGeolocationProviderTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set(
            'soul.location.cloudflare_headers_enabled',
            true,
        );
    }

    public function test_disabled_provider_returns_null(): void
    {
        config()->set(
            'soul.location.cloudflare_headers_enabled',
            false,
        );

        $provider = $this->provider(
            $this->validHeaders(),
        );

        $this->assertNull(
            $provider->fromIp('203.0.113.10'),
        );
    }

    public function test_missing_headers_return_null(): void
    {
        $provider = $this->provider([]);

        $this->assertNull(
            $provider->fromIp('203.0.113.10'),
        );
    }

    public function test_invalid_country_code_returns_null(): void
    {
        $headers = $this->validHeaders();
        $headers['HTTP_CF_IPCOUNTRY'] = 'PAK';

        $provider = $this->provider($headers);

        $this->assertNull(
            $provider->fromIp('203.0.113.10'),
        );
    }

    public function test_valid_headers_return_normalized_location(): void
    {
        $provider = $this->provider(
            $this->validHeaders(),
        );

        $location = $provider->fromIp(
            '203.0.113.10',
        );

        $this->assertInstanceOf(
            LocationData::class,
            $location,
        );

        $this->assertSame('Multan', $location->city);
        $this->assertSame('Punjab', $location->region);
        $this->assertSame('Pakistan', $location->country);
        $this->assertSame('PK', $location->countryCode);

        $this->assertSame(
            30.1575,
            $location->latitude,
        );

        $this->assertSame(
            71.5249,
            $location->longitude,
        );

        $this->assertSame(
            'Asia/Karachi',
            $location->timezone,
        );

        $this->assertSame('ip', $location->source);
        $this->assertTrue($location->isApproximate);
    }

    public function test_invalid_coordinates_become_null(): void
    {
        $headers = $this->validHeaders();

        $headers['HTTP_CF_IPLATITUDE'] = '999';
        $headers['HTTP_CF_IPLONGITUDE'] = 'invalid';

        $provider = $this->provider($headers);

        $location = $provider->fromIp(
            '203.0.113.10',
        );

        $this->assertInstanceOf(
            LocationData::class,
            $location,
        );

        $this->assertSame('Multan', $location->city);
        $this->assertSame('PK', $location->countryCode);
        $this->assertNull($location->latitude);
        $this->assertNull($location->longitude);
    }

    public function test_cloudflare_does_not_reverse_geocode_gps(): void
    {
        $provider = $this->provider(
            $this->validHeaders(),
        );

        $this->assertNull(
            $provider->fromCoordinates(
                latitude: 30.1575,
                longitude: 71.5249,
            ),
        );
    }

    private function provider(
        array $headers,
    ): CloudflareGeolocationProvider {
        $request = Request::create(
            '/',
            'GET',
            [],
            [],
            [],
            $headers,
        );

        return new CloudflareGeolocationProvider(
            $request,
        );
    }

    private function validHeaders(): array
    {
        return [
            'HTTP_CF_IPCITY' => 'Multan',
            'HTTP_CF_IPCOUNTRY' => 'PK',
            'HTTP_CF_REGION' => 'Punjab',
            'HTTP_CF_IPLATITUDE' => '30.1575',
            'HTTP_CF_IPLONGITUDE' => '71.5249',
            'HTTP_CF_TIMEZONE' => 'Asia/Karachi',
        ];
    }
}
