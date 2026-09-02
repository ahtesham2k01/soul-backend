<?php

namespace App\Enums\Profile;

enum ProfileStatus: string
{
    case Draft = 'draft';
    case Submitted = 'submitted';
    case AutomatedChecks = 'automated_checks';
    case Live = 'live';
    case ChangesRequired = 'changes_required';
    case PausedVerification = 'paused_verification';
    case Rejected = 'rejected';
    case AppealAvailable = 'appeal_available';
}
