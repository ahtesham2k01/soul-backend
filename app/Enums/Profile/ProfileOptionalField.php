<?php

namespace App\Enums\Profile;

enum ProfileOptionalField: string
{
    case Bio = 'bio';
    case Education = 'education';
    case HeightCm = 'height_cm';
    case JobTitle = 'job_title';
    case Employer = 'employer';
    case GrewUpIn = 'grew_up_in';
    case EthnicOrigin = 'ethnic_origin';
    case ReligiousPractice = 'religious_practice';
    case Prayer = 'prayer';
    case Diet = 'diet';
    case Dress = 'dress';
    case RelocationPreference = 'relocation_preference';
    case Interests = 'interests';
    case PersonalityTraits = 'personality_traits';
    case FamilyInvolvementPreference = 'family_involvement_preference';
}
