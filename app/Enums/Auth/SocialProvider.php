<?php

namespace App\Enums\Auth;

enum SocialProvider: string
{
    case Google = 'google';

    case Apple = 'apple';
}
