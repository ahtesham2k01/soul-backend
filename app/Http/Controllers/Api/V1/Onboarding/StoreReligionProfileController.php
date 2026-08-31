<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\StoreReligionProfileRequest;
use App\Models\ReligionTaxonomyNode;
use App\Models\UserReligionProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class StoreReligionProfileController extends Controller
{
    public function __invoke(
        StoreReligionProfileRequest $request,
    ): JsonResponse {
        $validated = $request->validated();
        $countryCode = $validated['country'] ?? null;

        $nodeQuery = ReligionTaxonomyNode::query()
            ->where('public_id', $validated['selected_node_id'])
            ->where('is_active', true);

        if ($countryCode !== null) {
            $nodeQuery->availableInCountry($countryCode);
        } else {
            $nodeQuery->whereDoesntHave('countries');
        }

        $node = $nodeQuery->first();

        if ($node === null) {
            return ApiResponse::error(
                code: 'RELIGION_OPTION_UNAVAILABLE',
                message: 'The selected religion option is not available for this country.',
                status: 422,
            );
        }

        $childrenQuery = $node->children()
            ->where('is_active', true);

        if ($countryCode !== null) {
            $childrenQuery->availableInCountry($countryCode);
        } else {
            $childrenQuery->whereDoesntHave('countries');
        }

        if ($childrenQuery->exists()) {
            return ApiResponse::error(
                code: 'RELIGION_SELECTION_INCOMPLETE',
                message: 'Continue to the next available religion step before saving.',
                status: 422,
            );
        }

        $profile = DB::transaction(
            fn (): UserReligionProfile => UserReligionProfile::query()
                ->updateOrCreate(
                    ['user_id' => $request->user()->getKey()],
                    [
                        'selected_node_id' => $node->getKey(),
                        'country_code' => $countryCode,
                    ],
                ),
        );

        $segments = explode('/', $node->path);
        $ancestorPaths = [];

        foreach (array_keys($segments) as $index) {
            $ancestorPaths[] = implode(
                '/',
                array_slice($segments, 0, $index + 1),
            );
        }

        $path = ReligionTaxonomyNode::query()
            ->whereIn('path', $ancestorPaths)
            ->where('is_active', true)
            ->orderByRaw(
                "LENGTH(path) - LENGTH(REPLACE(path, '/', ''))",
            )
            ->get()
            ->map(fn (ReligionTaxonomyNode $item): array => [
                'id' => $item->public_id,
                'type' => $item->type->value,
                'slug' => $item->slug,
            ])
            ->values();

        return ApiResponse::success(
            data: [
                'religion_profile' => [
                    'selected_node_id' => $node->public_id,
                    'country' => $profile->country_code,
                    'path' => $path,
                ],
            ],
            message: 'Religion profile saved successfully.',
        );
    }
}
