<?php

namespace App\Enums\Profile;

enum ProfessionStatus: string
{
    case Employed = 'employed';
    case SelfEmployed = 'self_employed';
    case Student = 'student';
    case Homemaker = 'homemaker';
    case Unemployed = 'unemployed';
    case Retired = 'retired';
    case Other = 'other';
}
