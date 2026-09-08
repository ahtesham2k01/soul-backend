<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\SpokenLanguage;
use App\Models\TranslationOverride;
use App\Support\ApiResponse;
use App\Support\Localization\TranslationCatalog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Validation\Rule;

class CatalogController extends Controller
{
    public function index(Request $request, TranslationCatalog $catalog): JsonResponse
    {
        $validated = $request->validate(['locale' => ['nullable', Rule::in(array_keys(config('soul.translations.locales', [])))]]);
        $locale = $validated['locale'] ?? config('soul.translations.fallback_locale');

        return ApiResponse::success([
            'locales' => collect(config('soul.translations.locales'))->map(fn (array $item, string $code): array => ['code' => $code, ...$item])->values(),
            'locale' => $locale,
            'translations' => $catalog->load($locale)['values'],
            'overridden_keys' => TranslationOverride::where('locale', $locale)->where('is_active', true)->pluck('key'),
            'spoken_languages' => SpokenLanguage::orderBy('sort_order')->orderBy('name')->get()->map(fn (SpokenLanguage $language): array => $language->only(['id', 'code', 'name', 'native_name', 'is_active', 'sort_order'])),
        ]);
    }

    public function updateTranslation(Request $request): JsonResponse
    {
        $locales = array_keys(config('soul.translations.locales', []));
        $base = json_decode(File::get(lang_path(config('soul.translations.fallback_locale').'.json')), true, flags: JSON_THROW_ON_ERROR);
        $validated = $request->validate(['locale' => ['required', Rule::in($locales)], 'key' => ['required', Rule::in(array_keys($base))], 'value' => ['required', 'string', 'max:5000'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $record = TranslationOverride::firstOrNew(['locale' => $validated['locale'], 'key' => $validated['key']]);
        $before = $record->exists ? $record->only(['value', 'is_active']) : null;
        $record->fill(['value' => $validated['value'], 'is_active' => true, 'updated_by_admin_id' => $request->user()->id])->save();
        $this->audit($request, $record, 'translation.updated', $before, $record->only(['locale', 'key', 'value', 'is_active']), $validated['reason']);

        return ApiResponse::success(['translation' => $record->only(['locale', 'key', 'value', 'is_active'])]);
    }

    public function updateLanguage(Request $request, string $language): JsonResponse
    {
        $record = SpokenLanguage::where('code', $language)->first();
        if (! $record) {
            return ApiResponse::error('LANGUAGE_NOT_FOUND', 'Spoken language not found.', 404);
        }
        $validated = $request->validate(['name' => ['required', 'string', 'max:120'], 'native_name' => ['required', 'string', 'max:120'], 'is_active' => ['required', 'boolean'], 'sort_order' => ['required', 'integer', 'min:0', 'max:65535'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $before = $record->toArray();
        $record->update(collect($validated)->except('reason')->all());
        $this->audit($request, $record, 'spoken_language.updated', $before, $record->toArray(), $validated['reason']);

        return ApiResponse::success(['language' => $record]);
    }

    private function audit(Request $request, object $subject, string $action, ?array $before, array $after, string $reason): void
    {
        AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => $action, 'subject_type' => $subject::class, 'subject_id' => $subject->id, 'before' => $before, 'after' => $after, 'reason' => $reason, 'ip_address' => $request->ip()]);
    }
}
