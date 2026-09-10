<?php

namespace Tests\Feature\Services\Auth;

use App\Models\User;
use App\Services\Auth\MobileTokenIssuer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MobileTokenIssuerTest extends TestCase
{
    use RefreshDatabase;

    public function test_issuing_token_prunes_expired_and_oldest_excess_sessions(): void
    {
        config()->set('soul.security.maximum_active_sessions', 3);
        $user = User::factory()->create();
        $oldest = $user->createToken('Oldest', ['mobile'], now()->addDays(90))->accessToken;
        $user->createToken('Middle', ['mobile'], now()->addDays(90));
        $newest = $user->createToken('Newest', ['mobile'], now()->addDays(90))->accessToken;
        $expired = $user->createToken('Expired', ['mobile'], now()->subMinute())->accessToken;

        $issued = app(MobileTokenIssuer::class)->issue($user, 'New phone');

        $this->assertSame(3, $user->tokens()->count());
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $oldest->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $expired->id]);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $newest->id]);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $issued->accessToken->id]);
    }
}
