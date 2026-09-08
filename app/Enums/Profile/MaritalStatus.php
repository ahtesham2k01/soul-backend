<?php

namespace App\Enums\Profile;

enum MaritalStatus: string
{
    case NeverMarried = 'never_married';
    case Married = 'married';
    case Separated = 'separated';
    case Divorced = 'divorced';
    case Widowed = 'widowed';
}
