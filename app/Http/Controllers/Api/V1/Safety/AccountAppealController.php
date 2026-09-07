<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Http\Controllers\Controller;
use App\Models\AccountAppeal;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AccountAppealController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return ApiResponse::success(['appeal' => $this->serialize($request->user()->accountAppeal)]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate(['statement' => ['required', 'string', 'min:20', 'max:2000']]);
        $user = $request->user();
        if ($user->status !== User::STATUS_BLOCKED) {
            return ApiResponse::error('ACCOUNT_APPEAL_NOT_AVAILABLE', 'An account appeal is not available.', 409);
        }
        $appeal = $user->accountAppeal()->firstOrCreate([], [
            'statement' => $validated['statement'], 'status' => 'pending', 'submitted_at' => now(),
        ]);

        return ApiResponse::success(['appeal' => $this->serialize($appeal)], 'Account appeal submitted.', 202);
    }

    private function serialize(?AccountAppeal $appeal): ?array
    {
        return $appeal ? [
            'id' => $appeal->public_id, 'status' => $appeal->status,
            'submitted_at' => $appeal->submitted_at->toIso8601String(),
            'resolved_at' => $appeal->resolved_at?->toIso8601String(),
        ] : null;
    }
}
