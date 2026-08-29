<?php

namespace App\Infrastructure\Location;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;
use Illuminate\Http\Request;
use Locale;

final class CloudflareGeolocationProvider implements GeolocationProvider
{
    public function __construct(
        private readonly Request $request,
    ) {
    }

    public function fromCoordinates(
        float $latitude,
        float $longitude,
    ): ?LocationData {
        /*
         * Cloudflare IP headers precise GPS reverse
         * geocoding provide nahi karte.
         */
        return null;
    }

    public function fromIp(
        string $ipAddress,
    ): ?LocationData {
        if (! config(
            'soul.location.cloudflare_headers_enabled',
            false,
        )) {
            return null;
        }

        $city = $this->cleanHeader('CF-IPCity');

        $countryCode = strtoupper(
            $this->cleanHeader('CF-IPCountry') ?? '',
        );

        if (
            $city === null
            || ! preg_match('/^[A-Z]{2}$/', $countryCode)
        ) {
            return null;
        }

        $latitude = $this->coordinate(
            header: 'CF-IPLatitude',
            minimum: -90,
            maximum: 90,
        );

        $longitude = $this->coordinate(
            header: 'CF-IPLongitude',
            minimum: -180,
            maximum: 180,
        );

        return new LocationData(
            city: $city,
            region: $this->cleanHeader('CF-Region'),
            country: $this->countryName($countryCode),
            countryCode: $countryCode,
            latitude: $latitude,
            longitude: $longitude,
            timezone: $this->cleanHeader('CF-Timezone'),
            source: 'ip',
            isApproximate: true,
        );
    }

    private function cleanHeader(string $name): ?string
    {
        $value = $this->request->header($name);

        if (! is_string($value)) {
            return null;
        }

        $value = trim($value);

        return $value === '' ? null : $value;
    }

    private function coordinate(
        string $header,
        float $minimum,
        float $maximum,
    ): ?float {
        $value = $this->cleanHeader($header);

        if ($value === null || ! is_numeric($value)) {
            return null;
        }

        $coordinate = (float) $value;

        if (
            $coordinate < $minimum
            || $coordinate > $maximum
        ) {
            return null;
        }

        return $coordinate;
    }

    private function countryName(string $countryCode): string
    {
        if (class_exists(Locale::class)) {
            $countryName = Locale::getDisplayRegion(
                '-'.$countryCode,
                'en',
            );

            if (
                is_string($countryName)
                && $countryName !== ''
                && $countryName !== $countryCode
            ) {
                return $countryName;
            }
        }

        /*
         * Intl extension unavailable ho to verified
         * ISO country code return hoga—fake name nahi.
         */
        return $countryCode;
    }
}
