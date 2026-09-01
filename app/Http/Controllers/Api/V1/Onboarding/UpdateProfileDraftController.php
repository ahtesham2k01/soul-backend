<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\UpdateProfileDraftRequest;
use App\Http\Resources\Api\V1\UserProfileDraftResource;
use App\Models\SpokenLanguage;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class UpdateProfileDraftController extends Controller
{
    public function __invoke(UpdateProfileDraftRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $profile = DB::transaction(function () use (
            $request,
            $validated,
        ): UserProfile {
            $profile = $request->user()->profile()->updateOrCreate(
                [],
                Arr::except($validated, [
                    'intentions',
                    'spoken_language_codes',
                ]),
            );

            if (array_key_exists('intentions', $validated)) {
                $profile->intentions()->delete();
                $profile->intentions()->createMany(
                    collect($validated['intentions'])
                        ->map(fn (string $intention): array => [
                            'intention' => $intention,
                        ])
                        ->all(),
                );
            }

            if (array_key_exists('spoken_language_codes', $validated)) {
                $languageIds = SpokenLanguage::query()
                    ->whereIn('code', $validated['spoken_language_codes'])
                    ->pluck('id');

                $profile->spokenLanguages()->sync($languageIds);
            }

            return $profile->load(['intentions', 'spokenLanguages']);
        });

        return ApiResponse::success(
            data: [
                'profile' => (new UserProfileDraftResource($profile))
                    ->resolve($request),
            ],
            message: 'Profile draft saved successfully.',
        );
    }
}
