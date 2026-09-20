<?php

namespace App\Http\Resources\Api\V1;

use App\Models\ProfilePhoto;
use App\Support\Media\CloudinaryDeliveryUrl;
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
        $deliveryUrl = app(CloudinaryDeliveryUrl::class);

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
            'url' => $this->visibility->value === 'public'
                && $this->moderation_status === ProfilePhotoModerationStatus::Approved
                && $this->format !== null
                && filled(config('soul.media.cloudinary.cloud_name'))
                    ? $deliveryUrl->forProfileImage(
                        $this->provider_asset_id,
                        $this->format,
                        $this->delivery_type,
                    )
                    : null,
        ];
    }
}
