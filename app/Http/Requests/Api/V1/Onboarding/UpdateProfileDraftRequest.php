<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use App\Enums\Profile\CurrentChildrenAnswer;
use App\Enums\Profile\FutureChildrenAnswer;
use App\Enums\Profile\Gender;
use App\Enums\Profile\LifestyleAnswer;
use App\Enums\Profile\MaritalStatus;
use App\Enums\Profile\ProfessionStatus;
use App\Enums\Profile\ProfileOptionalField;
use App\Enums\Profile\RelationshipIntention;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

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
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90', 'required_with:longitude'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180', 'required_with:latitude'],
            'nationality_country_code' => ['sometimes', 'nullable', 'string', 'size:2', 'regex:/^[A-Za-z]{2}$/'],
            'marital_status' => ['sometimes', 'nullable', Rule::enum(MaritalStatus::class)],
            'profession_status' => ['sometimes', 'nullable', Rule::enum(ProfessionStatus::class)],
            'smoking' => ['sometimes', 'nullable', Rule::enum(LifestyleAnswer::class)],
            'alcohol' => ['sometimes', 'nullable', Rule::enum(LifestyleAnswer::class)],
            'current_children' => ['sometimes', 'nullable', Rule::enum(CurrentChildrenAnswer::class)],
            'future_children' => ['sometimes', 'nullable', Rule::enum(FutureChildrenAnswer::class)],
            'bio' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'education' => ['sometimes', 'nullable', 'string', 'max:120'],
            'height_cm' => ['sometimes', 'nullable', 'integer', 'between:50,300'],
            'job_title' => ['sometimes', 'nullable', 'string', 'max:120'],
            'employer' => ['sometimes', 'nullable', 'string', 'max:160'],
            'grew_up_in' => ['sometimes', 'nullable', 'string', 'max:120'],
            'ethnic_origin' => ['sometimes', 'nullable', 'string', 'max:120'],
            'religious_practice' => ['sometimes', 'nullable', 'string', 'max:120'],
            'prayer' => ['sometimes', 'nullable', 'string', 'max:120'],
            'diet' => ['sometimes', 'nullable', 'string', 'max:120'],
            'dress' => ['sometimes', 'nullable', 'string', 'max:120'],
            'detailed_religion_visible' => ['sometimes', 'boolean'],
            'relocation_preference' => ['sometimes', 'nullable', 'string', 'max:64'],
            'family_involvement_preference' => ['sometimes', 'nullable', 'string', 'max:64'],
            'interests' => ['sometimes', 'array', 'max:15'],
            'interests.*' => ['string', 'max:80', 'distinct', 'regex:/\S/'],
            'personality_traits' => ['sometimes', 'array', 'max:5'],
            'personality_traits.*' => ['string', 'max:80', 'distinct', 'regex:/\S/'],
            'prefer_not_to_say_fields' => ['sometimes', 'array'],
            'prefer_not_to_say_fields.*' => ['string', 'distinct', Rule::enum(ProfileOptionalField::class)],
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

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $data = $validator->getData();
            $withheld = $data['prefer_not_to_say_fields'] ?? [];

            if (! is_array($withheld)) {
                return;
            }

            foreach ($withheld as $field) {
                if (is_string($field) && array_key_exists($field, $data) && filled($data[$field])) {
                    $validator->errors()->add($field, 'A field cannot be answered and marked prefer not to say at the same time.');
                }
            }
        });
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
