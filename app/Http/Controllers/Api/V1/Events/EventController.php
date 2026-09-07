<?php

namespace App\Http\Controllers\Api\V1\Events;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Support\ApiResponse;
use App\Support\Events\SerializesEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    use SerializesEvent;

    public function index(Request $request): JsonResponse
    {
        $page = Event::query()->with(['translations', 'registrations' => fn ($query) => $query->where('user_id', $request->user()->id)])
            ->where('status', 'published')->where('starts_at', '>', now())->orderBy('starts_at')->cursorPaginate(30);

        return ApiResponse::success(['events' => collect($page->items())->map(fn (Event $event) => $this->serializeEvent($event, app()->getLocale(), $request->user()->id))->values(), 'next_cursor' => $page->nextCursor()?->encode()]);
    }

    public function show(Request $request, string $event): JsonResponse
    {
        $record = Event::query()->with(['translations', 'registrations' => fn ($query) => $query->where('user_id', $request->user()->id)])
            ->where('public_id', $event)->where('status', 'published')->first();
        if ($record === null) {
            return ApiResponse::error('EVENT_NOT_FOUND', 'Event not found.', 404);
        }

        return ApiResponse::success(['event' => $this->serializeEvent($record, app()->getLocale(), $request->user()->id)]);
    }
}
