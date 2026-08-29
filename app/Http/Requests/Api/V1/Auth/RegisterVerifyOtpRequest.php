<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\In;

class RegisterVerifyOtpRequest extends FormRequest
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
            'verification_id' => [
                'required',
                'string',
                'ulid',
            ],
            'email' => [
                'required',
                'string',
                'email:rfc',
                'max:254',
            ],
            'code' => [
                'required',
                'string',
                'regex:/^\d{6}$/',
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
        if ($this->has('email')) {
            $this->merge([
                'email' => mb_strtolower(
                    trim(
                        (string) $this->input('email'),
                    ),
                ),
            ]);
        }

        if ($this->has('code')) {
            $this->merge([
                'code' => trim(
                    (string) $this->input('code'),
                ),
            ]);
        }

        if ($this->has('device_name')) {
            $this->merge([
                'device_name' => trim(
                    (string) $this->input('device_name'),
                ),
            ]);
        }
    }
}
