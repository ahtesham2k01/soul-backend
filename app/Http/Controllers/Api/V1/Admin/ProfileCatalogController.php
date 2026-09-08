<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\HelpCategory;
use App\Models\ProfileCatalogItem;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProfileCatalogController extends Controller
{
    public function index(): JsonResponse
    {
        return ApiResponse::success([
            'profile_items' => ProfileCatalogItem::with('translations')->orderBy('type')->orderBy('sort_order')->get()->map(fn ($item) => $this->profile($item)),
            'help_categories' => HelpCategory::with('translations')->orderBy('sort_order')->get()->map(fn ($item) => $this->help($item)),
        ]);
    }

    public function storeProfileItem(Request $request): JsonResponse
    {
        $data = $request->validate($this->profileRules());
        $item = ProfileCatalogItem::create(['type' => $data['type'], 'key' => $data['key'], 'sort_order' => $data['sort_order'] ?? 0, 'is_active' => true, 'updated_by_admin_id' => $request->user()->id]);
        $this->translations($item, $data['translations'], 'label');
        $this->audit($request, $item, 'profile_catalog.created', null, $this->profile($item->load('translations')), $data['reason']);

        return ApiResponse::success(['item' => $this->profile($item)], 'Catalog item created.', 201);
    }

    public function updateProfileItem(Request $request, string $item): JsonResponse
    {
        $record = ProfileCatalogItem::where('public_id', $item)->with('translations')->first();
        if (! $record) {
            return ApiResponse::error('CATALOG_ITEM_NOT_FOUND', 'Catalog item not found.', 404);
        }
        $data = $request->validate(['is_active' => ['required', 'boolean'], 'sort_order' => ['required', 'integer', 'min:0', 'max:65535'], 'translations' => ['required', 'array', 'min:1'], 'translations.en' => ['required', 'string', 'max:120'], 'translations.*' => ['string', 'max:120'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $before = $this->profile($record);
        $record->update(['is_active' => $data['is_active'], 'sort_order' => $data['sort_order'], 'updated_by_admin_id' => $request->user()->id]);
        $this->translations($record, $data['translations'], 'label');
        $after = $this->profile($record->load('translations'));
        $this->audit($request, $record, 'profile_catalog.updated', $before, $after, $data['reason']);

        return ApiResponse::success(['item' => $after]);
    }

    public function storeHelpCategory(Request $request): JsonResponse
    {
        $data = $request->validate(['key' => ['required', 'alpha_dash:ascii', 'max:80', 'unique:help_categories,key'], 'sort_order' => ['nullable', 'integer', 'min:0', 'max:65535'], 'translations' => ['required', 'array'], 'translations.en' => ['required', 'string', 'max:120'], 'translations.*' => ['string', 'max:120'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $item = HelpCategory::create(['key' => $data['key'], 'sort_order' => $data['sort_order'] ?? 0, 'is_active' => true, 'updated_by_admin_id' => $request->user()->id]);
        $this->translations($item, $data['translations'], 'name');
        $this->audit($request, $item, 'help_category.created', null, $this->help($item->load('translations')), $data['reason']);

        return ApiResponse::success(['category' => $this->help($item)], 'Help category created.', 201);
    }

    public function updateHelpCategory(Request $request, string $category): JsonResponse
    {
        $record = HelpCategory::where('public_id', $category)->with('translations')->first();
        if (! $record) {
            return ApiResponse::error('HELP_CATEGORY_NOT_FOUND', 'Help category not found.', 404);
        }
        $data = $request->validate(['is_active' => ['required', 'boolean'], 'sort_order' => ['required', 'integer', 'min:0', 'max:65535'], 'translations' => ['required', 'array'], 'translations.en' => ['required', 'string', 'max:120'], 'translations.*' => ['string', 'max:120'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $before = $this->help($record);
        $record->update(['is_active' => $data['is_active'], 'sort_order' => $data['sort_order'], 'updated_by_admin_id' => $request->user()->id]);
        $this->translations($record, $data['translations'], 'name');
        $after = $this->help($record->load('translations'));
        $this->audit($request, $record, 'help_category.updated', $before, $after, $data['reason']);

        return ApiResponse::success(['category' => $after]);
    }

    private function profileRules(): array
    {
        return ['type' => ['required', Rule::in(['interest', 'trait'])], 'key' => ['required', 'alpha_dash:ascii', 'max:80', Rule::unique('profile_catalog_items')->where(fn ($q) => $q->where('type', request('type')))], 'sort_order' => ['nullable', 'integer', 'min:0', 'max:65535'], 'translations' => ['required', 'array'], 'translations.en' => ['required', 'string', 'max:120'], 'translations.*' => ['string', 'max:120'], 'reason' => ['required', 'string', 'min:5', 'max:1000']];
    }

    private function translations($item, array $translations, string $field): void
    {
        foreach ($translations as $locale => $value) {
            $item->translations()->updateOrCreate(['locale' => $locale], [$field => $value]);
        }
    }

    private function profile($item): array
    {
        return ['id' => $item->public_id, 'type' => $item->type, 'key' => $item->key, 'is_active' => $item->is_active, 'sort_order' => $item->sort_order, 'translations' => $item->translations->pluck('label', 'locale')];
    }

    private function help($item): array
    {
        return ['id' => $item->public_id, 'key' => $item->key, 'is_active' => $item->is_active, 'sort_order' => $item->sort_order, 'translations' => $item->translations->pluck('name', 'locale')];
    }

    private function audit(Request $request, object $subject, string $action, ?array $before, array $after, string $reason): void
    {
        AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => $action, 'subject_type' => $subject::class, 'subject_id' => $subject->id, 'before' => $before, 'after' => $after, 'reason' => $reason, 'ip_address' => $request->ip()]);
    }
}
