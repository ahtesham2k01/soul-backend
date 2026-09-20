<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HelpCategory;
use App\Models\ProfileCatalogItem;
use App\Models\SpokenLanguage;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileCatalogController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $locale = app()->getLocale();

        return ApiResponse::success([
            'interests' => $this->profileItems('interest', $locale),
            'personality_traits' => $this->profileItems('trait', $locale),
            'spoken_languages' => SpokenLanguage::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get()
                ->map(fn (SpokenLanguage $language): array => [
                    'code' => $language->code,
                    'name' => $language->name,
                    'native_name' => $language->native_name,
                ])->values(),
            'help_categories' => HelpCategory::query()->where('is_active', true)
                ->with('translations')->orderBy('sort_order')->get()
                ->map(fn (HelpCategory $item): array => [
                    'id' => $item->public_id,
                    'key' => $item->key,
                    'name' => $this->translated($item->translations, $locale, 'name'),
                    'description' => $this->translated($item->translations, $locale, 'description'),
                ])->values(),
        ]);
    }

    private function profileItems(string $type, string $locale): array
    {
        return ProfileCatalogItem::query()->where('type', $type)->where('is_active', true)
            ->with('translations')->orderBy('sort_order')->get()
            ->map(fn (ProfileCatalogItem $item): array => [
                'id' => $item->public_id,
                'key' => $item->key,
                'label' => $this->translated($item->translations, $locale, 'label'),
            ])->values()->all();
    }

    private function translated($translations, string $locale, string $field): ?string
    {
        return $translations->firstWhere('locale', $locale)?->{$field}
            ?? $translations->firstWhere('locale', config('soul.translations.fallback_locale', 'en'))?->{$field};
    }
}
