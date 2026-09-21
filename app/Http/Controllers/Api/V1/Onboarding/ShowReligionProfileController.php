<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Models\ReligionTaxonomyNode;
use App\Models\UserReligionProfile;
use App\Support\ApiResponse;
use App\Support\Localization\LocaleResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowReligionProfileController extends Controller
{
    public function __invoke(
        Request $request,
        LocaleResolver $localeResolver,
    ): JsonResponse {
        $resolvedLocale = $localeResolver->resolve(
            requestedLocale: null,
            acceptLanguage: $request->header('Accept-Language'),
        );
        $fallbackLocale = config(
            'soul.translations.fallback_locale',
            'en',
        );
        $localeCandidates = array_values(array_unique([
            $resolvedLocale,
            strtolower(explode('-', $resolvedLocale)[0]),
            $fallbackLocale,
        ]));

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
            ->with([
                'translations' => fn ($query) => $query
                    ->whereIn('locale', $localeCandidates),
            ])
            ->orderByRaw(
                "LENGTH(path) - LENGTH(REPLACE(path, '/', ''))",
            )
            ->get()
            ->map(function (ReligionTaxonomyNode $node) use (
                $localeCandidates,
            ): array {
                $translation = null;

                foreach ($localeCandidates as $candidate) {
                    $translation = $node->translations
                        ->firstWhere('locale', $candidate);

                    if ($translation !== null) {
                        break;
                    }
                }

                return [
                    'id' => $node->public_id,
                    'type' => $node->type->value,
                    'slug' => $node->slug,
                    'label' => $translation?->label
                        ?? str($node->slug)->replace('-', ' ')->title()->toString(),
                    'label_locale' => $translation?->locale,
                ];
            })
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
