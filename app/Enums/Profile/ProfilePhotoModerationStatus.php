<?php

namespace App\Enums\Profile;

enum ProfilePhotoModerationStatus: string
{
    case Pending = 'pending';

    case Approved = 'approved';

    case Rejected = 'rejected';
}
