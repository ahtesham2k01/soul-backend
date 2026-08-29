<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Location\GeolocationProvider;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ResolveLocationRequest;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class ResolveLocationController extends Controller
{
    public function __invoke(
        ResolveLocationRequest $request,
        GeolocationProvider $geolocationProvider,
    ): JsonResponse {
        $validated = $request->validated();

        $location = $geolocationProvider->fromCoordinates(
            latitude: (float) $validated['latitude'],
            longitude: (float) $validated['longitude'],
        );

        if ($location === null) {
            return ApiResponse::success(
                data: [
                    'location' => null,
                    'location_status' => 'unavailable',
                ],
                message: 'Location could not be resolved.',
            );
        }

        return ApiResponse::success(
            data: [
                'location' => $location->toArray(),
                'location_status' => 'resolved',
            ],
            message: 'Location resolved successfully.',
        );
    }
}
