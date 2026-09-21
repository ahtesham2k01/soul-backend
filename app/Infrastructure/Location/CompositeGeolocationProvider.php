<?php

namespace App\Infrastructure\Location;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;

final class CompositeGeolocationProvider implements GeolocationProvider
{
    public function __construct(
        private readonly GeolocationProvider $ipProvider,
        private readonly GeolocationProvider $coordinateProvider,
    ) {
    }

    public function fromCoordinates(
        float $latitude,
        float $longitude,
    ): ?LocationData {
        return $this->coordinateProvider->fromCoordinates(
            latitude: $latitude,
            longitude: $longitude,
        );
    }

    public function fromIp(string $ipAddress): ?LocationData
    {
        return $this->ipProvider->fromIp($ipAddress);
    }
}
