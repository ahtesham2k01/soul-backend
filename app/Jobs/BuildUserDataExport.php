<?php

namespace App\Jobs;

use App\Models\DataExportRequest;
use App\Models\User;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\Query\Builder;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

class BuildUserDataExport implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(public readonly int $requestId) {}

    public function handle(): void
    {
        $claimed = DataExportRequest::query()->whereKey($this->requestId)->whereIn('status', ['pending', 'failed'])->update([
            'status' => 'processing',
            'processing_started_at' => now(),
        ]);
        if ($claimed !== 1) {
            return;
        }
        $request = DataExportRequest::query()->findOrFail($this->requestId);

        $stream = tmpfile();
        if ($stream === false) {
            throw new RuntimeException('Unable to create the private export stream.');
        }

        try {
            $user = User::query()->with(['profile.intentions', 'profile.spokenLanguages', 'religionProfile', 'privacySetting'])->findOrFail($request->user_id);
            $path = 'exports/'.$request->public_id.'.json';

            fwrite($stream, '{"schema_version":2,"format":"soul.member-data","generated_at":'.json_encode(now()->toIso8601String(), JSON_THROW_ON_ERROR));
            $this->writeValue($stream, 'account', $user->only(['public_id', 'name', 'email', 'phone', 'preferred_locale', 'email_verified_at', 'phone_verified_at', 'created_at']));
            $this->writeValue($stream, 'profile', $this->sanitize($user->profile?->toArray()));
            $this->writeValue($stream, 'religion', $this->sanitize($user->religionProfile?->toArray()));
            $this->writeValue($stream, 'privacy', $this->sanitize($user->privacySetting?->toArray()));

            $this->writeRows($stream, 'decisions', DB::table('profile_decisions')->where('actor_user_id', $user->id));
            $this->writeRows($stream, 'matches', DB::table('user_matches')->where(fn (Builder $query) => $query->where('first_user_id', $user->id)->orWhere('second_user_id', $user->id)));
            $this->writeRows($stream, 'messages', DB::table('messages')->whereIn('conversation_id', DB::table('conversations')->select('conversations.id')->join('user_matches', 'user_matches.id', '=', 'conversations.user_match_id')->where(fn (Builder $query) => $query->where('user_matches.first_user_id', $user->id)->orWhere('user_matches.second_user_id', $user->id))));
            $this->writeRows($stream, 'blocks', DB::table('user_blocks')->where('blocker_user_id', $user->id));
            $this->writeRows($stream, 'reports', DB::table('user_reports')->where('reporter_user_id', $user->id));
            $this->writeRows($stream, 'notifications', DB::table('user_notifications')->where('user_id', $user->id));
            $this->writeRows($stream, 'legal_acceptances', DB::table('legal_acceptances')->where('user_id', $user->id), ['ip_address', 'device_context_hash']);
            $this->writeRows($stream, 'verification_cases', DB::table('profile_verification_cases')->where('user_id', $user->id));
            $this->writeRows($stream, 'subscriptions', DB::table('user_subscriptions')->where('user_id', $user->id), ['provider_transaction_id']);
            $this->writeRows($stream, 'event_registrations', DB::table('event_registrations')->where('user_id', $user->id));
            $this->writeRows($stream, 'support_tickets', DB::table('support_tickets')->where('user_id', $user->id));
            $this->writeRows($stream, 'support_messages', DB::table('support_ticket_messages')->whereIn('support_ticket_id', DB::table('support_tickets')->select('id')->where('user_id', $user->id)));
            $this->writeRows($stream, 'support_attachments', DB::table('support_ticket_attachments')->whereIn('support_ticket_message_id', DB::table('support_ticket_messages')->select('support_ticket_messages.id')->join('support_tickets', 'support_tickets.id', '=', 'support_ticket_messages.support_ticket_id')->where('support_tickets.user_id', $user->id)), ['path', 'disk']);
            $this->writeRows($stream, 'devices', DB::table('user_devices')->where('user_id', $user->id), ['push_token', 'token_hash']);
            $this->writeRows($stream, 'notification_preferences', DB::table('notification_preferences')->where('user_id', $user->id));
            $this->writeRows($stream, 'profile_interests', DB::table('user_profile_interests')->where('user_profile_id', $user->profile?->id));
            $this->writeRows($stream, 'profile_traits', DB::table('user_profile_traits')->where('user_profile_id', $user->profile?->id));
            $this->writeRows($stream, 'profile_status_history', DB::table('profile_status_transitions')->where('user_profile_id', $user->profile?->id));
            $this->writeRows($stream, 'private_photo_access_requests', DB::table('private_photo_access_requests')->where(fn (Builder $query) => $query->where('owner_user_id', $user->id)->orWhere('requester_user_id', $user->id)));
            $this->writeRows($stream, 'private_photo_capture_events', DB::table('private_photo_capture_events')->where('owner_user_id', $user->id));
            $this->writeRows($stream, 'verification_appeals', DB::table('verification_appeals')->whereIn('profile_verification_case_id', DB::table('profile_verification_cases')->select('id')->where('user_id', $user->id)));
            $this->writeRows($stream, 'account_appeals', DB::table('account_appeals')->where('user_id', $user->id));
            $this->writeRows($stream, 'event_reports', DB::table('event_reports')->where('reporter_user_id', $user->id));
            fwrite($stream, '}');
            rewind($stream);

            if (! Storage::disk(config('soul.privacy.export_disk'))->put($path, $stream)) {
                throw new RuntimeException('Unable to store the private data export.');
            }

            $request->update(['status' => 'completed', 'processing_started_at' => null, 'file_path' => $path, 'completed_at' => now(), 'expires_at' => now()->addDays(7)]);
        } catch (Throwable $exception) {
            $request->update(['status' => 'failed', 'processing_started_at' => null, 'file_path' => null]);
            throw $exception;
        } finally {
            fclose($stream);
        }
    }

    private function writeValue($stream, string $key, mixed $value): void
    {
        fwrite($stream, ','.json_encode($key, JSON_THROW_ON_ERROR).':'.json_encode($value, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR));
    }

    private function writeRows($stream, string $key, Builder $query, array $hidden = []): void
    {
        fwrite($stream, ','.json_encode($key, JSON_THROW_ON_ERROR).':[');
        $first = true;

        foreach ($query->orderBy('id')->lazyById(500) as $row) {
            $data = $this->sanitize((array) $row, $hidden);
            fwrite($stream, ($first ? '' : ',').json_encode($data, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR));
            $first = false;
        }

        fwrite($stream, ']');
    }

    /**
     * Member exports deliberately use public identifiers only. Database primary
     * keys, foreign keys, credential material and storage locations are
     * implementation details, so they must never become part of a portable
     * account-data file.
     */
    private function sanitize(mixed $value, array $hidden = []): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        $safe = [];
        foreach ($value as $key => $item) {
            $key = (string) $key;
            if (
                in_array($key, $hidden, true)
                || $key === 'id'
                || $key === 'user_id'
                || (str_ends_with($key, '_id') && $key !== 'public_id')
                || str_ends_with($key, '_hash')
            ) {
                continue;
            }

            $safe[$key] = $this->sanitize($item, $hidden);
        }

        return $safe;
    }
}
