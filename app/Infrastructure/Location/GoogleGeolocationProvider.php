<?php

namespace App\Infrastructure\Location;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;
use Illuminate\Support\Facades\Http;
use Throwable;

final class GoogleGeolocationProvider implements GeolocationProvider
{
    private const ENDPOINT = 'https://maps.googleapis.com/maps/api/geocode/json';

    public function fromCoordinates(
        float $latitude,
        float $longitude,
    ): ?LocationData {
        $apiKey = trim((string) config('soul.location.google_geocoding.api_key'));

        if ($apiKey === '') {
            return null;
        }

        try {
            $response = Http::acceptJson()
                ->timeout((int) config('soul.location.google_geocoding.timeout_seconds', 4))
                ->get(self::ENDPOINT, [
                    'latlng' => number_format($latitude, 7, '.', '').','.number_format($longitude, 7, '.', ''),
                    'key' => $apiKey,
                    'language' => 'en',
                ]);
        } catch (Throwable) {
            return null;
        }

        if (! $response->successful()) {
            return null;
        }

        $payload = $response->json();

        if (! is_array($payload) || ($payload['status'] ?? null) !== 'OK') {
            return null;
        }

        $results = $payload['results'] ?? null;
        if (! is_array($results) || ! isset($results[0]) || ! is_array($results[0])) {
            return null;
        }

        $components = $results[0]['address_components'] ?? null;
        if (! is_array($components)) {
            return null;
        }

        $city = $this->component(
            $components,
            ['locality', 'postal_town', 'administrative_area_level_2', 'administrative_area_level_1'],
            'long_name',
        );
        $region = $this->component(
            $components,
            ['administrative_area_level_1'],
            'long_name',
        );
        $countryCode = strtoupper((string) $this->component(
            $components,
            ['country'],
            'short_name',
        ));
        $country = $this->component(
            $components,
            ['country'],
            'long_name',
        );

        if ($city === null || preg_match('/^[A-Z]{2}$/', $countryCode) !== 1) {
            return null;
        }

        return new LocationData(
            city: $city,
            region: $region,
            country: $country ?? $countryCode,
            countryCode: $countryCode,
            latitude: $latitude,
            longitude: $longitude,
            timezone: null,
            source: 'gps',
            isApproximate: false,
        );
    }

    public function fromIp(string $ipAddress): ?LocationData
    {
        return null;
    }

    /**
     * @param array<int, mixed> $components
     * @param array<int, string> $preferredTypes
     */
    private function component(
        array $components,
        array $preferredTypes,
        string $field,
    ): ?string {
        foreach ($preferredTypes as $preferredType) {
            foreach ($components as $component) {
                if (! is_array($component)) {
                    continue;
                }

                $types = $component['types'] ?? [];
                $value = $component[$field] ?? null;

                if (
                    is_array($types)
                    && in_array($preferredType, $types, true)
                    && is_string($value)
                    && trim($value) !== ''
                ) {
                    return trim($value);
                }
            }
        }

        return null;
    }
}
