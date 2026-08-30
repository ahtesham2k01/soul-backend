<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\In;

class GoogleSignInRequest extends FormRequest
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
            'id_token' => [
                'required',
                'string',
                'max:10000',
            ],
            'device_name' => [
                'required',
                'string',
                'min:2',
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
        if ($this->has('id_token')) {
            $this->merge([
                'id_token' => trim(
                    (string) $this->input(
                        'id_token',
                    ),
                ),
            ]);
        }

        if ($this->has('device_name')) {
            $this->merge([
                'device_name' => trim(
                    (string) $this->input(
                        'device_name',
                    ),
                ),
            ]);
        }
    }
}
