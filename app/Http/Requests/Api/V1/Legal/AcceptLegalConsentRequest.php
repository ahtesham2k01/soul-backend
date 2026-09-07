<?php

namespace App\Http\Requests\Api\V1\Legal;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AcceptLegalConsentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'terms_accepted' => ['required', 'accepted'],
            'terms_version' => ['required', Rule::in([(string) config('soul.legal.terms_version')])],
            'privacy_accepted' => ['required', 'accepted'],
            'privacy_version' => ['required', Rule::in([(string) config('soul.legal.privacy_version')])],
            'community_guidelines_accepted' => ['required', 'accepted'],
            'community_guidelines_version' => ['required', Rule::in([(string) config('soul.legal.community_guidelines_version')])],
            'community_commitment_accepted' => ['required', 'accepted'],
            'community_commitment_version' => ['required', Rule::in([(string) config('soul.legal.commitment_version')])],
            'device_id' => ['nullable', 'string', 'max:255'],
        ];
    }
}
