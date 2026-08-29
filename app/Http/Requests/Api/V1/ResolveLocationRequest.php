<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class ResolveLocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        /*
         * Endpoint authentication se pehle onboarding
         * screen par use hoga, isliye public hai.
         * Rate limiting route level par add hogi.
         */
        return true;
    }

    public function rules(): array
    {
        return [
            'latitude' => [
                'required',
                'numeric',
                'between:-90,90',
            ],

            'longitude' => [
                'required',
                'numeric',
                'between:-180,180',
            ],

            'accuracy_meters' => [
                'nullable',
                'numeric',
                'min:0',
                'max:100000',
            ],
        ];
    }

    /**
     * Only JSON request body is validated.
     * URL/query-string coordinates are intentionally ignored.
     */
    public function validationData(): array
    {
        return $this->json()->all();
    }

    public function messages(): array
    {
        return [
            'latitude.required' =>
                'Latitude is required.',

            'latitude.between' =>
                'Latitude must be between -90 and 90.',

            'longitude.required' =>
                'Longitude is required.',

            'longitude.between' =>
                'Longitude must be between -180 and 180.',
        ];
    }
}
