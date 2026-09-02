<?php

namespace App\Enums\Safety;

enum ReportCategory: string
{
    case FakeProfile = 'fake_profile';
    case Scam = 'scam';
    case Harassment = 'harassment';
    case NuditySexualContent = 'nudity_sexual_content';
    case Underage = 'underage';
    case FalseMaritalStatus = 'false_marital_status';
    case Other = 'other';
}
