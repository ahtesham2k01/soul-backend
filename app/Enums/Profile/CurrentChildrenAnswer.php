<?php

namespace App\Enums\Profile;

enum CurrentChildrenAnswer: string
{
    case No = 'no';
    case YesLivingWithMe = 'yes_living_with_me';
    case YesNotLivingWithMe = 'yes_not_living_with_me';
    case PreferNotToSay = 'prefer_not_to_say';
}
