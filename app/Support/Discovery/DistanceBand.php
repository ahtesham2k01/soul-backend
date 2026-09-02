<?php

namespace App\Support\Discovery;

final class DistanceBand
{
    public function kilometres(float $fromLat, float $fromLng, float $toLat, float $toLng): float
    {
        $latDelta = deg2rad($toLat - $fromLat);
        $lngDelta = deg2rad($toLng - $fromLng);
        $a = sin($latDelta / 2) ** 2 + cos(deg2rad($fromLat)) * cos(deg2rad($toLat)) * sin($lngDelta / 2) ** 2;

        return 6371 * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    public function label(float $kilometres): string
    {
        return match (true) {
            $kilometres < 1 => 'distance.less_than_1_km',
            $kilometres < 3.5 => 'distance.about_2_km',
            $kilometres < 7.5 => 'distance.about_5_km',
            $kilometres < 12.5 => 'distance.about_10_km',
            $kilometres < 25 => 'distance.about_20_km',
            $kilometres < 75 => 'distance.about_50_km',
            default => 'distance.more_than_50_km',
        };
    }
}
