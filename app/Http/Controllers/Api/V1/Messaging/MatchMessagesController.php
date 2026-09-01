<?php

namespace App\Http\Controllers\Api\V1\Messaging;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\UserMatch;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MatchMessagesController extends Controller
{
    public function index(Request $request, string $match): JsonResponse
    {
        $record = $this->activeMatch($request, $match);
        if ($record === null) return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        $conversation = Conversation::query()->where('user_match_id', $record->id)->first();
        if ($conversation === null) return ApiResponse::success(['messages' => [], 'next_cursor' => null]);
        $page = $conversation->messages()->orderByDesc('id')->cursorPaginate(50);
        return ApiResponse::success([
            'messages' => collect($page->items())->map(fn ($message) => [
                'id' => $message->public_id, 'body' => $message->body,
                'is_mine' => $message->sender_user_id === $request->user()->id,
                'sent_at' => $message->created_at->toIso8601String(),
            ])->values(), 'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function store(Request $request, string $match): JsonResponse
    {
        $validated = $request->validate([
            'body' => ['required', 'string', 'max:2000', 'regex:/\\S/'],
        ]);
        $record = $this->activeMatch($request, $match);
        if ($record === null) return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        $message = DB::transaction(function () use ($record, $request, $validated) {
            $conversation = Conversation::query()->firstOrCreate(['user_match_id' => $record->id]);
            $message = $conversation->messages()->create([
                'sender_user_id' => $request->user()->id, 'body' => trim($validated['body']),
            ]);
            $conversation->update(['last_message_at' => $message->created_at]);
            return $message;
        });
        return ApiResponse::success([
            'message' => ['id' => $message->public_id, 'body' => $message->body, 'is_mine' => true,
                'sent_at' => $message->created_at->toIso8601String()],
        ], 'Message sent successfully.', 201);
    }

    private function activeMatch(Request $request, string $publicId): ?UserMatch
    {
        $userId = $request->user()->id;
        return UserMatch::query()->where('public_id', $publicId)->where('status', 'active')
            ->where(fn ($q) => $q->where('first_user_id', $userId)->orWhere('second_user_id', $userId))
            ->whereNotExists(fn ($q) => $q->selectRaw('1')->from('user_blocks')
                ->whereColumn('blocker_user_id', 'user_matches.first_user_id')->whereColumn('blocked_user_id', 'user_matches.second_user_id')
                ->orWhere(fn ($q) => $q->whereColumn('blocker_user_id', 'user_matches.second_user_id')->whereColumn('blocked_user_id', 'user_matches.first_user_id')))
            ->first();
    }
}
