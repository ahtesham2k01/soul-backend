<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Enums\Safety\ReportCategory;
use App\Http\Controllers\Controller;
use App\Models\UserProfile;
use App\Models\UserReport;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ReportUserController extends Controller
{
    public function __invoke(Request $request, string $profile): JsonResponse
    {
        $validated = $request->validate([
            'category' => ['required', Rule::enum(ReportCategory::class)],
            'details' => ['nullable', 'string', 'max:1000'],
        ]);
        $target = UserProfile::query()->where('public_id', $profile)->first();
        if ($target === null || $target->user_id === $request->user()->id) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'Profile unavailable.', 404);
        }
        $report = UserReport::query()->create([
            'reporter_user_id' => $request->user()->id, 'reported_user_id' => $target->user_id,
            'category' => $validated['category'], 'details' => $validated['details'] ?? null, 'status' => 'pending',
        ]);

        return ApiResponse::success(['report_id' => $report->public_id, 'status' => 'pending'], 'Report submitted successfully.', 201);
    }
}
