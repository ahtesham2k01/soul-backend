<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use Illuminate\Foundation\Http\FormRequest;

class ReligionOptionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        /*
         * The catalog is required before profile completion, so it is public.
         * Route-level throttling protects it from unbounded requests.
         */
        return true;
    }

    public function rules(): array
    {
        return [
            'parent_id' => [
                'nullable',
                'ulid',
                'exists:religion_taxonomy_nodes,public_id',
            ],

            'locale' => [
                'nullable',
                'string',
                'max:35',
            ],

            'country' => [
                'nullable',
                'string',
                'size:2',
                'alpha:ascii',
            ],
        ];
    }
}
