<?php

namespace App\Http\Controllers\Api\V1\Discovery;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Discovery\UpdateDiscoveryPreferenceRequest;
use App\Models\DiscoveryPreference;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiscoveryPreferenceController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return ApiResponse::success([
            'preferences' => $this->serialize($request->user()->discoveryPreference),
        ]);
    }

    public function update(UpdateDiscoveryPreferenceRequest $request): JsonResponse
    {
        $preference = $request->user()->discoveryPreference()
            ->updateOrCreate([], $request->validated());

        return ApiResponse::success(
            ['preferences' => $this->serialize($preference->fresh())],
            'Discovery preferences saved successfully.',
        );
    }

    private function serialize(?DiscoveryPreference $preference): ?array
    {
        return $preference === null ? null : [
            'preferred_gender' => $preference->preferred_gender->value,
            'minimum_age' => $preference->minimum_age,
            'maximum_age' => $preference->maximum_age,
            'same_country_only' => $preference->same_country_only,
            'religion_mode' => $preference->religion_mode->value,
        ];
    }
}
