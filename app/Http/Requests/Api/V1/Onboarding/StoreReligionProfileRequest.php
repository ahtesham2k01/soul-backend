<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreReligionProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'selected_node_id' => [
                'required',
                'string',
                'size:26',
                Rule::exists(
                    'religion_taxonomy_nodes',
                    'public_id',
                )->where('is_active', true),
            ],
            'country' => [
                'nullable',
                'string',
                'size:2',
                'regex:/^[A-Za-z]{2}$/',
            ],
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->filled('country')) {
            $this->merge([
                'country' => strtoupper(
                    (string) $this->input('country'),
                ),
            ]);
        }
    }
}
