<?php

namespace App\Http\Resources\Api\V1;

use App\Models\UserProfile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin UserProfile */
class PublicUserProfileResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $withheld = $this->withheldFields->pluck('field')->map->value->all();
        $optional = fn (string $field): mixed => in_array($field, $withheld, true) ? null : $this->{$field};
        $religion = $this->user->religionProfile;

        return [
            'id' => $this->public_id,
            'first_name' => $this->first_name,
            'age' => $this->date_of_birth->age,
            'gender' => $this->gender->value,
            'marital_status' => $this->marital_status,
            'city' => $this->user->privacySetting?->show_city === false ? null : $this->city_name,
            'country' => $this->country_code,
            'nationality_country_code' => $this->nationality_country_code,
            'bio' => $optional('bio'),
            'education' => $optional('education'),
            'height_cm' => $optional('height_cm'),
            'job_title' => $optional('job_title'),
            'employer' => $optional('employer'),
            'grew_up_in' => $optional('grew_up_in'),
            'ethnic_origin' => $optional('ethnic_origin'),
            'religious_practice' => $optional('religious_practice'),
            'prayer' => $optional('prayer'),
            'diet' => $optional('diet'),
            'dress' => $optional('dress'),
            'relocation_preference' => $optional('relocation_preference'),
            'family_involvement_preference' => $optional('family_involvement_preference'),
            'intentions' => $this->intentions->pluck('intention')->map->value->values(),
            'interests' => in_array('interests', $withheld, true) ? null : $this->interests->pluck('value')->values(),
            'personality_traits' => in_array('personality_traits', $withheld, true) ? null : $this->personalityTraits->pluck('value')->values(),
            'spoken_languages' => $this->spokenLanguages->map(fn ($language): array => [
                'code' => $language->code,
                'name' => $language->name,
                'native_name' => $language->native_name,
            ])->values(),
            'religion' => $religion?->rootNode === null ? null : [
                'id' => $religion->rootNode->public_id,
                'slug' => $religion->rootNode->slug,
                'details_visible' => $this->detailed_religion_visible,
                'selected_path' => $this->detailed_religion_visible
                    ? $religion->selectedNode->ancestorsAndSelf()->map(fn ($node): array => [
                        'id' => $node->public_id,
                        'type' => $node->type->value,
                        'slug' => $node->slug,
                    ])->values()
                    : [],
            ],
            'photos' => $this->photos->map(fn ($photo): array => [
                'id' => $photo->public_id,
                'position' => $photo->position,
            ])->values(),
        ];
    }
}
