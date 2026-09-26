<?php

namespace App\Support\Safety;

use App\Models\Message;
use App\Models\ProfileDecision;
use App\Models\SafetyCase;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SafetyRiskMonitor
{
    public function observeDecisionVelocity(User $user): void
    {
        $window = max(1, (int) config('soul.safety.decision_velocity_window_minutes', 10));
        $threshold = max(2, (int) config('soul.safety.decision_velocity_threshold', 80));
        $count = ProfileDecision::query()
            ->where('actor_user_id', $user->getKey())
            ->where('updated_at', '>=', now()->subMinutes($window))
            ->count();

        if ($count >= $threshold) {
            $this->record(
                $user,
                'suspicious_decision_velocity',
                'medium',
                ['event_count' => $count, 'window_minutes' => $window, 'threshold' => $threshold],
                'decision:'.$window,
            );
        }
    }

    public function observeMessageActivity(User $user, Message $message): void
    {
        $velocityWindow = max(1, (int) config('soul.safety.message_velocity_window_minutes', 15));
        $velocityThreshold = max(2, (int) config('soul.safety.message_velocity_threshold', 60));
        $messageCount = Message::query()
            ->where('sender_user_id', $user->getKey())
            ->where('created_at', '>=', now()->subMinutes($velocityWindow))
            ->count();

        if ($messageCount >= $velocityThreshold) {
            $this->record(
                $user,
                'suspicious_message_velocity',
                'medium',
                ['event_count' => $messageCount, 'window_minutes' => $velocityWindow, 'threshold' => $velocityThreshold],
                'message:'.$velocityWindow,
            );
        }

        $normalized = Str::lower(preg_replace('/\s+/u', ' ', trim($message->body)) ?? trim($message->body));
        if (mb_strlen($normalized) < 12) {
            return;
        }

        $repeatWindow = max(1, (int) config('soul.safety.repeated_message_window_minutes', 60));
        $conversationThreshold = max(2, (int) config('soul.safety.repeated_message_conversation_threshold', 5));
        $conversationCount = Message::query()
            ->where('sender_user_id', $user->getKey())
            ->where('body', $message->body)
            ->where('created_at', '>=', now()->subMinutes($repeatWindow))
            ->distinct()
            ->count('conversation_id');

        if ($conversationCount >= $conversationThreshold) {
            $this->record(
                $user,
                'repeated_message_pattern',
                'high',
                [
                    'conversation_count' => $conversationCount,
                    'window_minutes' => $repeatWindow,
                    'threshold' => $conversationThreshold,
                    'content_length_band' => $this->lengthBand(mb_strlen($normalized)),
                ],
                'message-copy:'.$this->fingerprint($normalized),
            );
        }
    }

    public function observeRepeatedMedia(User $actor, User $existingOwner, string $providerAssetId): void
    {
        if ($actor->is($existingOwner)) {
            return;
        }

        $possibleBanEvasion = in_array($existingOwner->status, [User::STATUS_BLOCKED, User::STATUS_SUSPENDED], true);
        $this->record(
            $actor,
            $possibleBanEvasion ? 'possible_ban_evasion_media' : 'repeated_media_attempt',
            $possibleBanEvasion ? 'high' : 'medium',
            [
                'asset_reuse' => true,
                'previous_owner_restricted' => $possibleBanEvasion,
            ],
            'media:'.$this->fingerprint($providerAssetId),
        );
    }

    /** @param array<string, bool|int|string> $evidence */
    private function record(User $user, string $type, string $severity, array $evidence, string $fingerprint): void
    {
        $signalKey = $this->fingerprint($type.'|'.$fingerprint);
        $reason = match ($type) {
            'suspicious_decision_velocity' => 'Unusually rapid discovery activity requires review.',
            'suspicious_message_velocity' => 'Unusually rapid messaging activity requires review.',
            'repeated_message_pattern' => 'The same message pattern appeared across multiple conversations.',
            'possible_ban_evasion_media' => 'A restricted account media signal may have reappeared.',
            default => 'A media asset appears to have been reused across accounts.',
        };

        DB::transaction(function () use ($user, $type, $signalKey, $severity, $reason, $evidence): void {
            $case = SafetyCase::query()
                ->where('user_id', $user->getKey())
                ->where('type', $type)
                ->where('signal_key', $signalKey)
                ->where('status', 'open')
                ->lockForUpdate()
                ->first();

            if ($case === null) {
                SafetyCase::query()->create([
                    'user_id' => $user->getKey(),
                    'type' => $type,
                    'signal_key' => $signalKey,
                    'severity' => $severity,
                    'status' => 'open',
                    'reason' => $reason,
                    'evidence' => $evidence,
                    'occurrence_count' => 1,
                    'first_observed_at' => now(),
                    'last_observed_at' => now(),
                ]);

                return;
            }

            $case->update([
                'severity' => $severity,
                'evidence' => $evidence,
                'occurrence_count' => $case->occurrence_count + 1,
                'last_observed_at' => now(),
            ]);
        });
    }

    private function fingerprint(string $value): string
    {
        $key = (string) config('app.key', 'soul-safety-local-key');

        return hash_hmac('sha256', $value, $key);
    }

    private function lengthBand(int $length): string
    {
        return match (true) {
            $length <= 40 => '12-40',
            $length <= 120 => '41-120',
            $length <= 500 => '121-500',
            default => '501-plus',
        };
    }
}
