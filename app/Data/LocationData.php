<?php

namespace App\Data;

final readonly class LocationData
{
    public function __construct(
        public string $city,
        public ?string $region,
        public string $country,
        public string $countryCode,
        public ?float $latitude,
        public ?float $longitude,
        public ?string $timezone,
        public string $source,
        public bool $isApproximate,
    ) {
    }

    public function toArray(): array
    {
        return [
            'city' => $this->city,
            'region' => $this->region,
            'country' => $this->country,
            'country_code' => $this->countryCode,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'timezone' => $this->timezone,
            'source' => $this->source,
            'is_approximate' => $this->isApproximate,
        ];
    }
}
