<?php

namespace App\Http\Resources\Api\V1;

use App\Models\ProfilePhoto;
use App\Enums\Profile\ProfilePhotoModerationStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin ProfilePhoto */
class ProfilePhotoResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'position' => $this->position,
            'visibility' => $this->visibility->value,
            'moderation_status' => $this->moderation_status->value,
            'rejection_reason' => $this->rejection_reason,
            'correction_screen' => $this->moderation_status
                === ProfilePhotoModerationStatus::Rejected
                    ? 'onboarding.photos'
                    : null,
            'face_detected' => $this->face_detected,
            'screenshot_protection_enabled' => $this->screenshot_protection_enabled,
        ];
    }
}
