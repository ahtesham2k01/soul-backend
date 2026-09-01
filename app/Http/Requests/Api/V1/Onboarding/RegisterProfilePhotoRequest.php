<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use App\Enums\Profile\ProfilePhotoVisibility;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterProfilePhotoRequest extends FormRequest
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
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'position' => ['required', 'integer', 'between:1,3'],
            'provider_asset_id' => [
                'required', 'string', 'max:255', 'regex:/^[A-Za-z0-9_\/.-]+$/',
            ],
            'provider_version' => ['required', 'integer', 'min:1'],
            'provider_signature' => [
                'required', 'string', 'regex:/^(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})$/',
            ],
            'visibility' => [
                'required',
                Rule::enum(ProfilePhotoVisibility::class),
                Rule::prohibitedIf(
                    (int) $this->route('position') === 1
                    && $this->input('visibility') !== ProfilePhotoVisibility::Public->value,
                ),
            ],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'position' => $this->route('position'),
            'provider_signature' => strtolower(
                (string) $this->input('provider_signature'),
            ),
        ]);
    }
}
