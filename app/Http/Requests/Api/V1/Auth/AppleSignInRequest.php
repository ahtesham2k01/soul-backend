<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\In;

class AppleSignInRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, In|string>>
     */
    public function rules(): array
    {
        return [
            'identity_token' => [
                'required',
                'string',
                'max:10000',
            ],
            'raw_nonce' => [
                'required',
                'string',
                'min:16',
                'max:256',
            ],
            'device_name' => [
                'required',
                'string',
                'min:2',
                'max:100',
            ],
            'given_name' => [
                'sometimes',
                'nullable',
                'string',
                'max:100',
            ],
            'family_name' => [
                'sometimes',
                'nullable',
                'string',
                'max:100',
            ],
            'locale' => [
                'sometimes',
                'string',
                'max:15',
                Rule::in(
                    array_keys(
                        config(
                            'soul.translations.locales',
                            [],
                        ),
                    ),
                ),
            ],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach ([
            'identity_token',
            'raw_nonce',
            'device_name',
            'given_name',
            'family_name',
        ] as $field) {
            if ($this->has($field)) {
                $value = trim(
                    (string) $this->input(
                        $field,
                    ),
                );

                $this->merge([
                    $field => $value === ''
                        ? null
                        : $value,
                ]);
            }
        }
    }
}
