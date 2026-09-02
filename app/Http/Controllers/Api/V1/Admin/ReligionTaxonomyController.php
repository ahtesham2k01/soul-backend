<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\Profile\ReligionNodeType;
use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\ReligionTaxonomyNode;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ReligionTaxonomyController extends Controller
{
    public function index(): JsonResponse
    {
        $nodes = ReligionTaxonomyNode::query()
            ->with(['translations', 'countries', 'parent:id,public_id'])
            ->orderBy('path')->get();

        return ApiResponse::success(['nodes' => $nodes->map(fn (ReligionTaxonomyNode $node): array => $this->serialize($node))->values()]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validateNode($request);
        $parent = $this->parent($validated['parent_id'] ?? null);
        if (($validated['parent_id'] ?? null) !== null && $parent === null) {
            return ApiResponse::error('RELIGION_PARENT_NOT_FOUND', 'Parent taxonomy option not found.', 422);
        }

        $node = DB::transaction(function () use ($request, $validated, $parent): ReligionTaxonomyNode {
            $node = ReligionTaxonomyNode::query()->create([
                'parent_id' => $parent?->id,
                'type' => $validated['type'],
                'slug' => $validated['slug'],
                'path' => ($parent ? $parent->path.'/' : '').$validated['slug'],
                'is_active' => $validated['is_active'] ?? true,
                'sort_order' => $validated['sort_order'] ?? 0,
            ]);
            $this->syncRelations($node, $validated);
            $this->audit($request, $node, 'religion_taxonomy.created', null, $validated);

            return $node;
        });

        return ApiResponse::success(['node' => $this->serialize($node->load(['translations', 'countries', 'parent']))], 'Religion option created.', 201);
    }

    public function update(Request $request, ReligionTaxonomyNode $node): JsonResponse
    {
        $validated = $this->validateNode($request, $node);
        $parent = $this->parent($validated['parent_id'] ?? null);
        if (($validated['parent_id'] ?? null) !== null && $parent === null) {
            return ApiResponse::error('RELIGION_PARENT_NOT_FOUND', 'Parent taxonomy option not found.', 422);
        }
        if ($parent && ($parent->is($node) || str_starts_with($parent->path.'/', $node->path.'/'))) {
            return ApiResponse::error('RELIGION_HIERARCHY_CYCLE', 'A taxonomy option cannot be moved below itself.', 409);
        }

        DB::transaction(function () use ($request, $validated, $parent, $node): void {
            $before = $this->serialize($node->load(['translations', 'countries', 'parent']));
            $oldPath = $node->path;
            $newPath = ($parent ? $parent->path.'/' : '').$validated['slug'];
            $node->update([
                'parent_id' => $parent?->id,
                'type' => $validated['type'],
                'slug' => $validated['slug'],
                'path' => $newPath,
                'is_active' => $validated['is_active'],
                'sort_order' => $validated['sort_order'],
            ]);
            if ($oldPath !== $newPath) {
                ReligionTaxonomyNode::query()->where('path', 'like', $oldPath.'/%')->get()->each(
                    fn (ReligionTaxonomyNode $child) => $child->update(['path' => $newPath.substr($child->path, strlen($oldPath))]),
                );
            }
            $this->syncRelations($node, $validated);
            $this->audit($request, $node, 'religion_taxonomy.updated', $before, $validated);
        });

        return ApiResponse::success(['node' => $this->serialize($node->refresh()->load(['translations', 'countries', 'parent']))], 'Religion option updated.');
    }

    private function validateNode(Request $request, ?ReligionTaxonomyNode $node = null): array
    {
        return $request->validate([
            'parent_id' => ['nullable', 'string'],
            'type' => ['required', Rule::enum(ReligionNodeType::class)],
            'slug' => ['required', 'alpha_dash', 'max:80', Rule::unique('religion_taxonomy_nodes', 'slug')->where('parent_id', $this->parent($request->input('parent_id'))?->id)->ignore($node?->id)],
            'is_active' => ['required', 'boolean'],
            'sort_order' => ['required', 'integer', 'min:0', 'max:65535'],
            'translations' => ['required', 'array', 'min:1'],
            'translations.*.locale' => ['required', 'string', 'max:15', 'distinct'],
            'translations.*.label' => ['required', 'string', 'max:120'],
            'translations.*.description' => ['nullable', 'string', 'max:500'],
            'country_codes' => ['present', 'array'],
            'country_codes.*' => ['string', 'size:2', 'distinct'],
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);
    }

    private function parent(?string $publicId): ?ReligionTaxonomyNode
    {
        return $publicId ? ReligionTaxonomyNode::query()->where('public_id', $publicId)->first() : null;
    }

    private function syncRelations(ReligionTaxonomyNode $node, array $validated): void
    {
        $node->translations()->delete();
        $node->translations()->createMany($validated['translations']);
        $node->countries()->delete();
        $node->countries()->createMany(array_map(fn (string $code): array => ['country_code' => strtoupper($code)], $validated['country_codes']));
    }

    private function audit(Request $request, ReligionTaxonomyNode $node, string $action, ?array $before, array $after): void
    {
        AdminAuditLog::query()->create(['admin_user_id' => $request->user()->id, 'action' => $action, 'subject_type' => ReligionTaxonomyNode::class, 'subject_id' => $node->id, 'before' => $before, 'after' => $after, 'reason' => $after['reason'], 'ip_address' => $request->ip()]);
    }

    private function serialize(ReligionTaxonomyNode $node): array
    {
        return ['id' => $node->public_id, 'parent_id' => $node->parent?->public_id, 'type' => $node->type->value, 'slug' => $node->slug, 'path' => $node->path, 'is_active' => $node->is_active, 'sort_order' => $node->sort_order, 'translations' => $node->translations->map->only(['locale', 'label', 'description'])->values(), 'country_codes' => $node->countries->pluck('country_code')->sort()->values()];
    }
}
