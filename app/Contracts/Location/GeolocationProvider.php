<?php

namespace App\Contracts\Location;

use App\Data\LocationData;

interface GeolocationProvider
{
    /**
     * Resolve precise location from device GPS coordinates.
     */
    public function fromCoordinates(
        float $latitude,
        float $longitude,
    ): ?LocationData;

    /**
     * Resolve approximate location from the request IP address.
     */
    public function fromIp(
        string $ipAddress,
    ): ?LocationData;
}
