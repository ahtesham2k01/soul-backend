<?php

namespace App\Http\Requests\Api\V1\Discovery;

use App\Enums\Profile\DiscoveryLocationMode;
use App\Enums\Profile\Gender;
use App\Enums\Profile\RelationshipIntention;
use App\Enums\Profile\ReligionDiscoveryMode;
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
            'religion_mode' => ['sometimes', Rule::enum(ReligionDiscoveryMode::class)],
            'location_mode' => ['sometimes', Rule::enum(DiscoveryLocationMode::class)],
            'radius_km' => ['sometimes', 'nullable', 'integer', 'between:1,500'],
            'selected_locations' => ['sometimes', 'array', 'min:1', 'max:10', 'required_if:location_mode,selected'],
            'selected_locations.*.country_code' => ['required', 'string', 'size:2', 'regex:/^[A-Za-z]{2}$/'],
            'selected_locations.*.city_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'intentions' => ['sometimes', 'array', 'max:3'],
            'intentions.*' => ['string', 'distinct', Rule::enum(RelationshipIntention::class)],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (! is_array($this->input('selected_locations'))) {
            return;
        }

        $this->merge(['selected_locations' => collect($this->input('selected_locations'))->map(function ($location) {
            if (is_array($location) && isset($location['country_code'])) {
                $location['country_code'] = strtoupper($location['country_code']);
            }

            return $location;
        })->all()]);
    }
}
