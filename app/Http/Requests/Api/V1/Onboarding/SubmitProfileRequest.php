<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class SubmitProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'terms_accepted' => ['required', 'accepted'],
            'terms_version' => [
                'required', 'string',
                Rule::in([(string) config('soul.legal.terms_version')]),
            ],
            'privacy_accepted' => ['required', 'accepted'],
            'privacy_version' => [
                'required', 'string',
                Rule::in([(string) config('soul.legal.privacy_version')]),
            ],
            'device_id' => ['nullable', 'string', 'max:255'],
        ];
    }
}
