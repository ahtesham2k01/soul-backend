<?php

namespace App\Infrastructure\Location;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;

final class NullGeolocationProvider implements GeolocationProvider
{
    public function fromCoordinates(
        float $latitude,
        float $longitude,
    ): ?LocationData {
        return null;
    }

    public function fromIp(
        string $ipAddress,
    ): ?LocationData {
        return null;
    }
}
