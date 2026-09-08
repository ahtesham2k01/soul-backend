<?php

namespace App\Http\Controllers\Api\V1\Messaging;

use App\Http\Controllers\Controller;
use App\Models\UserMatch;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RealtimeSubscriptionController extends Controller
{
    public function __invoke(Request $request, string $match): JsonResponse
    {
        $userId = $request->user()->id;
        $record = UserMatch::query()->where('public_id', $match)->where('status', 'active')
            ->where(fn ($query) => $query->where('first_user_id', $userId)->orWhere('second_user_id', $userId))
            ->whereHas('firstUser', fn ($query) => $query->where('status', 'active'))
            ->whereHas('secondUser', fn ($query) => $query->where('status', 'active'))->first();
        if (! $record) {
            return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        }

        return ApiResponse::success([
            'channel' => 'private-match.'.$record->public_id,
            'authorization_endpoint' => url('/api/v1/broadcasting/auth'),
            'events' => ['chat.message.created', 'chat.messages.read', 'chat.typing.changed'],
            'typing_ttl_seconds' => 8,
        ]);
    }
}
