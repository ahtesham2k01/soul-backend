<?php

namespace Tests\Feature\Console;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class CleanupCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_cleanup_removes_expired_sessions_and_their_push_devices(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);

        $active = $user->createToken(
            'Active Device',
            ['mobile'],
            now()->addDay(),
        );

        $expired = $user->createToken(
            'Expired Device',
            ['mobile'],
            now()->subMinute(),
        );

        $pushToken = 'expired-session-push-token';

        $user->devices()->create([
            'personal_access_token_id' => $expired->accessToken->id,
            'platform' => 'android',
            'push_token' => $pushToken,
            'token_hash' => hash('sha256', $pushToken),
            'device_name' => 'Expired Device',
            'last_seen_at' => now(),
        ]);

        Artisan::call('soul:cleanup');

        $this->assertDatabaseHas('personal_access_tokens', [
            'id' => $active->accessToken->id,
        ]);
        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $expired->accessToken->id,
        ]);
        $this->assertDatabaseMissing('user_devices', [
            'token_hash' => hash('sha256', $pushToken),
        ]);
    }
}
