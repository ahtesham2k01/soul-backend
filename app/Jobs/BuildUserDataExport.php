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

            fwrite($stream, '{"generated_at":'.json_encode(now()->toIso8601String(), JSON_THROW_ON_ERROR));
            $this->writeValue($stream, 'account', $user->only(['public_id', 'name', 'email', 'phone', 'preferred_locale', 'email_verified_at', 'phone_verified_at', 'created_at']));
            $this->writeValue($stream, 'profile', $user->profile?->toArray());
            $this->writeValue($stream, 'religion', $user->religionProfile?->toArray());
            $this->writeValue($stream, 'privacy', $user->privacySetting?->toArray());

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
            $this->writeRows($stream, 'devices', DB::table('user_devices')->where('user_id', $user->id), ['push_token', 'token_hash']);
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
            $data = (array) $row;
            foreach (array_merge(['id', 'user_id'], $hidden) as $column) {
                unset($data[$column]);
            }
            fwrite($stream, ($first ? '' : ',').json_encode($data, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR));
            $first = false;
        }

        fwrite($stream, ']');
    }
}
