<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\ReligionOptionsRequest;
use App\Models\ReligionTaxonomyNode;
use App\Support\ApiResponse;
use App\Support\Localization\LocaleResolver;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;

class ReligionOptionsController extends Controller
{
    public function __invoke(
        ReligionOptionsRequest $request,
        LocaleResolver $localeResolver,
    ): JsonResponse {
        $validated = $request->validated();

        $requestedLocale = $validated['locale'] ?? null;

        $resolvedLocale = $localeResolver->resolve(
            requestedLocale: $requestedLocale,
            acceptLanguage: $request->header('Accept-Language'),
        );

        $fallbackLocale = config(
            'soul.translations.fallback_locale',
            'en',
        );

        $countryCode = isset($validated['country'])
            ? strtoupper($validated['country'])
            : null;

        $parent = isset($validated['parent_id'])
            ? ReligionTaxonomyNode::query()
                ->where('public_id', $validated['parent_id'])
                ->where('is_active', true)
                ->firstOrFail()
            : null;

        $localeCandidates = array_values(array_unique([
            $resolvedLocale,
            strtolower(explode('-', $resolvedLocale)[0]),
            $fallbackLocale,
        ]));

        $nodes = ReligionTaxonomyNode::query()
            ->where('parent_id', $parent?->id)
            ->where('is_active', true)
            ->when(
                $countryCode !== null,
                fn (Builder $query): Builder => $query
                    ->availableInCountry($countryCode),
                fn (Builder $query): Builder => $query
                    ->whereDoesntHave('countries'),
            )
            ->with([
                'translations' => fn (Builder $query): Builder => $query
                    ->whereIn('locale', $localeCandidates),
            ])
            ->withCount([
                'children as available_children_count' =>
                    function ($query) use ($countryCode): void {
                        $query->where('is_active', true);

                        if ($countryCode !== null) {
                            $query->availableInCountry($countryCode);

                            return;
                        }

                        $query->whereDoesntHave('countries');
                    },
            ])
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        $options = $nodes->map(
            function (ReligionTaxonomyNode $node) use (
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
                    'has_children' => $node->available_children_count > 0,
                ];
            },
        )->values();

        return ApiResponse::success(
            data: [
                'parent' => $parent === null
                    ? null
                    : [
                        'id' => $parent->public_id,
                        'type' => $parent->type->value,
                        'slug' => $parent->slug,
                    ],
                'options' => $options,
            ],
            message: 'Religion options loaded successfully.',
            meta: [
                'locale' => $resolvedLocale,
                'country' => $countryCode,
            ],
        );
    }
}
