<?php

namespace App\Enums\Profile;

enum DiscoveryLocationMode: string
{
    case Current = 'current';
    case Selected = 'selected';
    case Anywhere = 'anywhere';
}
