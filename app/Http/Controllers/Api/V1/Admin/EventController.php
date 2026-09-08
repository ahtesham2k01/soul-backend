<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Event;
use App\Models\EventReport;
use App\Support\ApiResponse;
use App\Support\Events\SerializesEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class EventController extends Controller
{
    use SerializesEvent;

    public function index(Request $request): JsonResponse
    {
        $page = Event::query()->with(['translations', 'registrations'])->latest('id')->cursorPaginate(30);

        return ApiResponse::success(['events' => collect($page->items())->map(fn (Event $event) => $this->serializeEvent($event, app()->getLocale(), null, true))->values(), 'next_cursor' => $page->nextCursor()?->encode()]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validateEvent($request);
        $event = DB::transaction(function () use ($request, $validated): Event {
            $event = Event::query()->create([...$this->attributes($validated), 'created_by_admin_id' => $request->user()->id, 'status' => 'draft']);
            $event->translations()->createMany($validated['translations']);
            $this->audit($request, $event, 'event.created', null, ['status' => 'draft']);

            return $event;
        });

        return ApiResponse::success(['event' => $this->serializeEvent($event->load(['translations', 'registrations']), app()->getLocale(), null, true)], 'Event draft created.', 201);
    }

    public function update(Request $request, string $event): JsonResponse
    {
        $record = Event::query()->where('public_id', $event)->first();
        if (! $record) {
            return ApiResponse::error('EVENT_NOT_FOUND', 'Event not found.', 404);
        }
        $validated = $this->validateEvent($request, $record);
        DB::transaction(function () use ($request, $record, $validated): void {
            $before = $record->only(['type', 'starts_at', 'ends_at', 'city', 'country_code', 'capacity']);
            $record->update($this->attributes($validated));
            foreach ($validated['translations'] as $translation) {
                $record->translations()->updateOrCreate(['locale' => $translation['locale']], $translation);
            }
            $this->audit($request, $record, 'event.updated', $before, $record->only(array_keys($before)));
        });

        return ApiResponse::success(['event' => $this->serializeEvent($record->load(['translations', 'registrations']), app()->getLocale(), null, true)]);
    }

    public function status(Request $request, string $event): JsonResponse
    {
        $validated = $request->validate(['status' => ['required', Rule::in(['published', 'draft', 'cancelled'])], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $record = Event::query()->where('public_id', $event)->first();
        if (! $record) {
            return ApiResponse::error('EVENT_NOT_FOUND', 'Event not found.', 404);
        }
        if ($validated['status'] === 'published' && $record->starts_at->isPast()) {
            return ApiResponse::error('EVENT_DATE_PASSED', 'A past event cannot be published.', 409);
        }
        $before = ['status' => $record->status];
        $record->update(['status' => $validated['status'], 'published_at' => $validated['status'] === 'published' ? now() : $record->published_at]);
        $this->audit($request, $record, 'event.status_changed', $before, ['status' => $record->status], $validated['reason']);

        return ApiResponse::success(['id' => $record->public_id, 'status' => $record->status]);
    }

    public function reports(): JsonResponse
    {
        $page = EventReport::query()->with('event:id,public_id')->where('status', 'pending')->latest('id')->cursorPaginate(30);

        return ApiResponse::success(['reports' => collect($page->items())->map(fn ($x) => ['id' => $x->public_id, 'event_id' => $x->event->public_id, 'category' => $x->category, 'details' => $x->details, 'created_at' => $x->created_at->toIso8601String()])->values(), 'next_cursor' => $page->nextCursor()?->encode()]);
    }

    public function decideReport(Request $request, string $report): JsonResponse
    {
        $v = $request->validate(['decision' => ['required', Rule::in(['resolved', 'dismissed', 'cancel_event'])], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $record = EventReport::where('public_id', $report)->where('status', 'pending')->first();
        if (! $record) {
            return ApiResponse::error('EVENT_REPORT_NOT_FOUND', 'Pending event report not found.', 404);
        }
        DB::transaction(function () use ($request, $record, $v) {
            $record->update(['status' => $v['decision'], 'reviewed_by_admin_id' => $request->user()->id, 'reviewed_at' => now()]);
            if ($v['decision'] === 'cancel_event') {
                $record->event()->update(['status' => 'cancelled']);
            }
            $this->audit($request, $record, 'event_report.'.$v['decision'], ['status' => 'pending'], ['status' => $v['decision']], $v['reason']);
        });

        return ApiResponse::success(['id' => $record->public_id, 'status' => $record->status]);
    }

    private function validateEvent(Request $request, ?Event $event = null): array
    {
        return $request->validate(['type' => ['required', Rule::in(['online', 'physical'])], 'starts_at' => ['required', 'date', 'after:now'], 'ends_at' => ['nullable', 'date', 'after:starts_at'], 'timezone' => ['required', 'timezone'], 'city' => ['nullable', 'required_if:type,physical', 'string', 'max:120'], 'country_code' => ['nullable', 'required_if:type,physical', 'string', 'size:2'], 'online_url' => ['nullable', 'required_if:type,online', 'url', 'max:2048'], 'capacity' => ['nullable', 'integer', 'min:1', 'max:1000000', Rule::when($event, fn () => ['gte:'.($event?->registration_count ?? 0)])], 'translations' => ['required', 'array', 'min:1', 'max:20'], 'translations.*.locale' => ['required', 'string', 'max:12', 'distinct'], 'translations.*.title' => ['required', 'string', 'max:160'], 'translations.*.description' => ['required', 'string', 'max:5000']]);
    }

    private function attributes(array $v): array
    {
        return ['type' => $v['type'], 'starts_at' => $v['starts_at'], 'ends_at' => $v['ends_at'] ?? null, 'timezone' => $v['timezone'], 'city' => $v['type'] === 'physical' ? $v['city'] : null, 'country_code' => $v['type'] === 'physical' ? strtoupper($v['country_code']) : null, 'online_url' => $v['type'] === 'online' ? $v['online_url'] : null, 'capacity' => $v['capacity'] ?? null];
    }

    private function audit(Request $request, $subject, string $action, ?array $before, array $after, ?string $reason = null): void
    {
        AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => $action, 'subject_type' => $subject::class, 'subject_id' => $subject->id, 'before' => $before, 'after' => $after, 'reason' => $reason, 'ip_address' => $request->ip()]);
    }
}
