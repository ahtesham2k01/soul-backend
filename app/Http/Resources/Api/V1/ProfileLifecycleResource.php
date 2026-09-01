<?php

namespace App\Http\Resources\Api\V1;

use App\Models\UserProfile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin UserProfile */
class ProfileLifecycleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'status' => $this->profile_status->value,
            'submitted_at' => $this->submitted_at?->toIso8601String(),
            'checks_completed_at' => $this->checks_completed_at?->toIso8601String(),
            'live_at' => $this->live_at?->toIso8601String(),
            'reason' => $this->status_reason,
            'correction_screen' => $this->correction_screen,
        ];
    }
}
