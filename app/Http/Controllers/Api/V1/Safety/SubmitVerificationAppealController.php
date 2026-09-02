<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Http\Controllers\Controller;
use App\Models\ProfileVerificationCase;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SubmitVerificationAppealController extends Controller
{
    public function __invoke(Request $request, string $case): JsonResponse
    {
        $validated = $request->validate(['statement' => ['required', 'string', 'min:20', 'max:1500', 'regex:/\\S/']]);
        $record = ProfileVerificationCase::query()->where('public_id', $case)
            ->where('user_id', $request->user()->id)->first();
        if ($record === null) return ApiResponse::error('VERIFICATION_CASE_NOT_FOUND', 'Verification case not found.', 404);
        $appeal = $record->appeal()->first();
        if ($appeal === null && $record->status !== 'appeal_available') return ApiResponse::error('APPEAL_NOT_AVAILABLE', 'This case cannot be appealed.', 409);
        $appeal ??= $record->appeal()->create([
            'user_id' => $request->user()->id, 'statement' => trim($validated['statement']),
            'status' => 'pending', 'submitted_at' => now(),
        ]);
        $record->update(['status' => 'appeal_pending']);
        return ApiResponse::success([
            'appeal' => ['id' => $appeal->public_id, 'status' => $appeal->status,
                'submitted_at' => $appeal->submitted_at->toIso8601String()],
        ], 'Appeal submitted successfully.', 202);
    }
}
