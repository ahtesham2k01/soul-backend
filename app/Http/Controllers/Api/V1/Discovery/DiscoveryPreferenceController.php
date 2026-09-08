<?php

namespace App\Http\Controllers\Api\V1\Discovery;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Discovery\UpdateDiscoveryPreferenceRequest;
use App\Models\DiscoveryPreference;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DiscoveryPreferenceController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return ApiResponse::success([
            'preferences' => $this->serialize($request->user()->discoveryPreference?->load(['locations', 'intentions'])),
        ]);
    }

    public function update(UpdateDiscoveryPreferenceRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $locations = $validated['selected_locations'] ?? null;
        $intentions = $validated['intentions'] ?? null;
        unset($validated['selected_locations'], $validated['intentions']);

        $preference = DB::transaction(function () use ($request, $validated, $locations, $intentions): DiscoveryPreference {
            $preference = $request->user()->discoveryPreference()->updateOrCreate([], $validated);

            if ($locations !== null) {
                $preference->locations()->delete();
                $preference->locations()->createMany($locations);
            }

            if ($intentions !== null) {
                $preference->intentions()->delete();
                $preference->intentions()->createMany(collect($intentions)->map(fn ($value) => ['intention' => $value])->all());
            }

            return $preference;
        });

        return ApiResponse::success(
            ['preferences' => $this->serialize($preference->fresh()->load(['locations', 'intentions']))],
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
            'location_mode' => $preference->location_mode->value,
            'radius_km' => $preference->radius_km,
            'selected_locations' => $preference->locations->map->only(['country_code', 'city_name'])->values(),
            'intentions' => $preference->intentions->map(fn ($item) => $item->intention->value)->values(),
        ];
    }
}
