<?php

namespace App\Http\Resources\Api\V1;

use App\Models\UserProfile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin UserProfile */
class UserProfileDraftResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'profile_status' => $this->profile_status,
            'first_name' => $this->first_name,
            'date_of_birth' => $this->date_of_birth?->toDateString(),
            'gender' => $this->gender?->value,
            'city_name' => $this->city_name,
            'country_code' => $this->country_code,
            'nationality_country_code' => $this->nationality_country_code,
            'marital_status' => $this->marital_status,
            'profession_status' => $this->profession_status,
            'smoking' => $this->smoking,
            'alcohol' => $this->alcohol,
            'current_children' => $this->current_children,
            'future_children' => $this->future_children,
            'bio' => $this->bio,
            'education' => $this->education,
            'height_cm' => $this->height_cm,
            'job_title' => $this->job_title,
            'employer' => $this->employer,
            'grew_up_in' => $this->grew_up_in,
            'ethnic_origin' => $this->ethnic_origin,
            'religious_practice' => $this->religious_practice,
            'prayer' => $this->prayer,
            'diet' => $this->diet,
            'dress' => $this->dress,
            'detailed_religion_visible' => $this->detailed_religion_visible,
            'relocation_preference' => $this->relocation_preference,
            'family_involvement_preference' => $this->family_involvement_preference,
            'interests' => $this->interests->pluck('value')->values(),
            'personality_traits' => $this->personalityTraits->pluck('value')->values(),
            'prefer_not_to_say_fields' => $this->withheldFields
                ->pluck('field')
                ->map(fn ($field): string => $field->value)
                ->values(),
            'intentions' => $this->intentions
                ->pluck('intention')
                ->map(fn ($intention): string => $intention->value)
                ->values(),
            'spoken_languages' => $this->spokenLanguages
                ->map(fn ($language): array => [
                    'code' => $language->code,
                    'name' => $language->name,
                    'native_name' => $language->native_name,
                ])
                ->values(),
        ];
    }
}
