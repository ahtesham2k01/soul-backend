<?php

namespace App\Enums\Profile;

enum ProfilePhotoVisibility: string
{
    case Public = 'public';

    case Private = 'private';
}
