<?php

namespace App\Enums\Auth;

enum EmailVerificationPurpose: string
{
    case Register = 'register';

    case Login = 'login';
}
