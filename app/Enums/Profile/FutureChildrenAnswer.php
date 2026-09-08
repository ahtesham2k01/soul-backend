<?php

namespace App\Enums\Profile;

enum FutureChildrenAnswer: string
{
    case WantChildren = 'want_children';
    case DoNotWantChildren = 'do_not_want_children';
    case OpenToChildren = 'open_to_children';
    case NotSure = 'not_sure';
    case PreferNotToSay = 'prefer_not_to_say';
}
