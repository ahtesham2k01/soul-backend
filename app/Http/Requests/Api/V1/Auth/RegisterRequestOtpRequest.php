<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\In;

class RegisterRequestOtpRequest extends FormRequest
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
            'email' => [
                'required',
                'string',
                'email:rfc',
                'max:254',
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
        if ($this->has('email')) {
            $this->merge([
                'email' => mb_strtolower(
                    trim(
                        (string) $this->input('email'),
                    ),
                ),
            ]);
        }
    }
}
