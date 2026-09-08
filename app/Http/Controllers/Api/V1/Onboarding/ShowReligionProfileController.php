<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Models\ReligionTaxonomyNode;
use App\Models\UserReligionProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowReligionProfileController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $profile = UserReligionProfile::query()
            ->with(['selectedNode', 'rootNode'])
            ->where('user_id', $request->user()->getKey())
            ->first();

        if ($profile === null) {
            return ApiResponse::success(
                data: ['religion_profile' => null],
                message: 'Religion profile has not been completed.',
            );
        }

        $selectedNode = $profile->selectedNode;
        $segments = explode('/', $selectedNode->path);
        $ancestorPaths = [];

        foreach (array_keys($segments) as $index) {
            $ancestorPaths[] = implode(
                '/',
                array_slice($segments, 0, $index + 1),
            );
        }

        $path = ReligionTaxonomyNode::query()
            ->whereIn('path', $ancestorPaths)
            ->orderByRaw(
                "LENGTH(path) - LENGTH(REPLACE(path, '/', ''))",
            )
            ->get()
            ->map(fn (ReligionTaxonomyNode $node): array => [
                'id' => $node->public_id,
                'type' => $node->type->value,
                'slug' => $node->slug,
            ])
            ->values();

        return ApiResponse::success(
            data: [
                'religion_profile' => [
                    'selected_node_id' => $selectedNode->public_id,
                    'root_node_id' => $profile->rootNode?->public_id,
                    'country' => $profile->country_code,
                    'path' => $path,
                ],
            ],
            message: 'Religion profile loaded successfully.',
        );
    }
}
