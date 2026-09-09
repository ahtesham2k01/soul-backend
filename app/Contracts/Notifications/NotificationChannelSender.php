<?php

namespace App\Contracts\Notifications;

use App\Models\NotificationDeliveryAttempt;

interface NotificationChannelSender
{
    public function send(NotificationDeliveryAttempt $attempt): ?string;
}
