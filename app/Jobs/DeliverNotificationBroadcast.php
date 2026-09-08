<?php

namespace App\Jobs;

use App\Models\NotificationBroadcast;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DeliverNotificationBroadcast implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;

    public array $backoff = [60, 300, 900, 3600];

    public function __construct(public int $broadcastId) {}

    public function handle(): void
    {
        $broadcast = NotificationBroadcast::find($this->broadcastId);
        if (! $broadcast || ! in_array($broadcast->status, ['queued', 'processing'], true)) {
            return;
        }
        $broadcast->update(['status' => 'processing']);
        $query = User::query()->where('status', User::STATUS_ACTIVE)->whereNull('admin_role');
        if ($broadcast->audience_type === 'country') {
            $query->whereHas('profile', fn ($q) => $q->where('country_code', strtoupper($broadcast->audience_value)));
        }
        if ($broadcast->audience_type === 'locale') {
            $query->where('preferred_locale', $broadcast->audience_value);
        }
        if ($broadcast->category === 'marketing') {
            $query->whereHas('notificationPreference', fn ($p) => $p->where('marketing', true)->orWhere('push_marketing', true)->orWhere('email_marketing', true));
        }
        $query->select('id')->chunkById(500, function ($users) use ($broadcast) {
            $now = now();
            DB::table('user_notifications')->insertOrIgnore($users->map(function ($user) use ($broadcast, $now) {
                $channels = ['in_app'];
                if ($broadcast->category === 'safety') {
                    $channels = ['in_app', 'push', 'email'];
                } else {
                    $preference = DB::table('notification_preferences')->where('user_id', $user->id)->first();
                    if ($preference?->push_marketing) {
                        $channels[] = 'push';
                    }
                    if ($preference?->email_marketing) {
                        $channels[] = 'email';
                    }
                }

                return ['public_id' => (string) Str::ulid(), 'broadcast_id' => $broadcast->id, 'user_id' => $user->id, 'type' => 'broadcast', 'deduplication_key' => hash('sha256', $user->id.'|broadcast|'.$broadcast->id), 'data' => json_encode(['title' => $broadcast->title, 'body' => $broadcast->body, 'category' => $broadcast->category], JSON_THROW_ON_ERROR), 'delivery_channels' => json_encode($channels, JSON_THROW_ON_ERROR), 'created_at' => $now, 'updated_at' => $now];
            })->all());
        });
        $delivered = DB::table('user_notifications')->where('broadcast_id', $broadcast->id)->count();
        $broadcast->update(['status' => 'completed', 'delivered_count' => $delivered, 'completed_at' => now()]);
    }
}
