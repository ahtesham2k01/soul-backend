<?php

namespace App\Support\Notifications;

use RuntimeException;

final class NotificationProviderException extends RuntimeException
{
    public function __construct(
        public readonly string $failureCode,
        public readonly bool $retryable,
    ) {
        parent::__construct($failureCode);
    }

    public static function permanent(string $failureCode): self
    {
        return new self($failureCode, false);
    }

    public static function transient(string $failureCode): self
    {
        return new self($failureCode, true);
    }
}
