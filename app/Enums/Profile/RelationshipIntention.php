<?php

namespace App\Enums\Profile;

enum RelationshipIntention: string
{
    case Marriage = 'marriage';

    case SeriousRelationship = 'serious_relationship';

    case CasualDating = 'casual_dating';
}
