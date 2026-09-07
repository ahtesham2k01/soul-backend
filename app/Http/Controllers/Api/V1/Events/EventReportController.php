<?php

namespace App\Http\Controllers\Api\V1\Events;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventReport;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class EventReportController extends Controller
{
    public function __invoke(Request $request, string $event): JsonResponse
    {
        $v = $request->validate(['category' => ['required', Rule::in(['misleading', 'unsafe', 'spam', 'other'])], 'details' => ['nullable', 'required_if:category,other', 'string', 'max:1000']]);
        $record = Event::where('public_id', $event)->where('status', 'published')->first();
        if (! $record) {
            return ApiResponse::error('EVENT_NOT_FOUND', 'Event not found.', 404);
        }
        $report = EventReport::firstOrCreate(['event_id' => $record->id, 'reporter_user_id' => $request->user()->id], [...$v, 'status' => 'pending']);

        return ApiResponse::success(['report' => ['id' => $report->public_id, 'status' => $report->status], 'duplicate' => ! $report->wasRecentlyCreated], 'Event report received.', $report->wasRecentlyCreated ? 201 : 200);
    }
}
