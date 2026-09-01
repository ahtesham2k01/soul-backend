<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use App\Enums\Profile\Gender;
use App\Enums\Profile\RelationshipIntention;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileDraftRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, array<mixed>>
     */
    public function rules(): array
    {
        return [
            'first_name' => ['sometimes', 'nullable', 'string', 'max:80'],
            'date_of_birth' => [
                'sometimes',
                'nullable',
                Rule::date()->beforeOrEqual(today()->subYears(18)),
            ],
            'gender' => ['sometimes', 'nullable', Rule::enum(Gender::class)],
            'city_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'country_code' => ['sometimes', 'nullable', 'string', 'size:2', 'regex:/^[A-Za-z]{2}$/'],
            'nationality_country_code' => ['sometimes', 'nullable', 'string', 'size:2', 'regex:/^[A-Za-z]{2}$/'],
            'marital_status' => ['sometimes', 'nullable', 'string', 'max:32'],
            'profession_status' => ['sometimes', 'nullable', 'string', 'max:64'],
            'smoking' => ['sometimes', 'nullable', 'string', 'max:32'],
            'alcohol' => ['sometimes', 'nullable', 'string', 'max:32'],
            'current_children' => ['sometimes', 'nullable', 'string', 'max:32'],
            'future_children' => ['sometimes', 'nullable', 'string', 'max:32'],
            'bio' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'education' => ['sometimes', 'nullable', 'string', 'max:120'],
            'height_cm' => ['sometimes', 'nullable', 'integer', 'between:50,300'],
            'job_title' => ['sometimes', 'nullable', 'string', 'max:120'],
            'employer' => ['sometimes', 'nullable', 'string', 'max:160'],
            'grew_up_in' => ['sometimes', 'nullable', 'string', 'max:120'],
            'ethnic_origin' => ['sometimes', 'nullable', 'string', 'max:120'],
            'relocation_preference' => ['sometimes', 'nullable', 'string', 'max:64'],
            'family_involvement_preference' => ['sometimes', 'nullable', 'string', 'max:64'],
            'intentions' => ['sometimes', 'array', 'max:3'],
            'intentions.*' => ['string', 'distinct', Rule::enum(RelationshipIntention::class)],
            'spoken_language_codes' => ['sometimes', 'array'],
            'spoken_language_codes.*' => [
                'string',
                'distinct',
                Rule::exists('spoken_languages', 'code')->where('is_active', true),
            ],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['country_code', 'nationality_country_code'] as $field) {
            if ($this->filled($field)) {
                $this->merge([
                    $field => strtoupper((string) $this->input($field)),
                ]);
            }
        }
    }
}
