<?php

namespace App\Http\Requests\Api\V1\Discovery;

use App\Enums\Profile\Gender;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateDiscoveryPreferenceRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'preferred_gender' => ['required', Rule::enum(Gender::class)],
            'minimum_age' => ['required', 'integer', 'between:18,100'],
            'maximum_age' => ['required', 'integer', 'between:18,100', 'gte:minimum_age'],
            'same_country_only' => ['required', 'boolean'],
        ];
    }
}
