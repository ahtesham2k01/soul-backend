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
    private const OPTIONAL_SCALAR_FIELDS = [
        'bio', 'education', 'height_cm', 'job_title', 'employer', 'grew_up_in',
        'ethnic_origin', 'religious_practice', 'prayer', 'diet', 'dress',
        'relocation_preference', 'family_involvement_preference',
    ];

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
                    'interests',
                    'personality_traits',
                    'prefer_not_to_say_fields',
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

            if (array_key_exists('interests', $validated)) {
                $profile->interests()->delete();
                $profile->interests()->createMany($this->values($validated['interests']));
            }

            if (array_key_exists('personality_traits', $validated)) {
                $profile->personalityTraits()->delete();
                $profile->personalityTraits()->createMany($this->values($validated['personality_traits']));
            }

            $this->syncWithheldFields($profile, $validated);

            return $profile->load([
                'intentions', 'spokenLanguages', 'interests',
                'personalityTraits', 'withheldFields',
            ]);
        });

        return ApiResponse::success(
            data: [
                'profile' => (new UserProfileDraftResource($profile))
                    ->resolve($request),
            ],
            message: 'Profile draft saved successfully.',
        );
    }

    /** @return list<array{value: string}> */
    private function values(array $values): array
    {
        return collect($values)
            ->map(fn (string $value): array => ['value' => trim($value)])
            ->all();
    }

    private function syncWithheldFields(UserProfile $profile, array $validated): void
    {
        $withheld = $validated['prefer_not_to_say_fields'] ?? null;

        if (is_array($withheld)) {
            $profile->withheldFields()->delete();
            $profile->withheldFields()->createMany(
                collect($withheld)->map(fn (string $field): array => ['field' => $field])->all(),
            );

            foreach ($withheld as $field) {
                if ($field === 'interests') {
                    $profile->interests()->delete();
                } elseif ($field === 'personality_traits') {
                    $profile->personalityTraits()->delete();
                } elseif (in_array($field, self::OPTIONAL_SCALAR_FIELDS, true)) {
                    $profile->forceFill([$field => null])->save();
                }
            }
        }

        $explicitOptionalFields = collect([
            ...self::OPTIONAL_SCALAR_FIELDS,
            'interests',
            'personality_traits',
        ])->filter(fn (string $field): bool => array_key_exists($field, $validated));

        $profile->withheldFields()
            ->whereIn('field', $explicitOptionalFields->diff($withheld ?? []))
            ->delete();
    }
}
