<?php

namespace App\Http\Controllers\Api\V1\Legal;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Legal\AcceptLegalConsentRequest;
use App\Support\ApiResponse;
use App\Support\Legal\LegalConsent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LegalConsentController extends Controller
{
    public function show(Request $request, LegalConsent $consent): JsonResponse
    {
        return ApiResponse::success(['legal' => $consent->status($request->user())]);
    }

    public function store(AcceptLegalConsentRequest $request, LegalConsent $consent): JsonResponse
    {
        $validated = $request->validated();
        $consent->record($request->user(), $request, [
            'terms' => $validated['terms_version'],
            'privacy' => $validated['privacy_version'],
            'community_guidelines' => $validated['community_guidelines_version'],
            'community_commitment' => $validated['community_commitment_version'],
        ], 'settings_reconsent');

        return ApiResponse::success(['legal' => $consent->status($request->user())], 'Current legal documents accepted.');
    }
}
