<?php

namespace Tests\Feature\Models;

use App\Enums\Auth\SocialProvider;
use App\Models\SocialAccount;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SocialAccountModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_link_google_and_apple_accounts(): void
    {
        $user = User::factory()->create();

        $google = $user->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'google-user-123',
            'provider_email' => 'user@gmail.com',
            'provider_email_verified' => true,
        ]);

        $apple = $user->socialAccounts()->create([
            'provider' => SocialProvider::Apple,
            'provider_user_id' => 'apple-user-456',
            'provider_email' => 'user@privaterelay.appleid.com',
            'provider_email_verified' => true,
        ]);

        $this->assertSame(
            SocialProvider::Google,
            $google->provider,
        );

        $this->assertSame(
            SocialProvider::Apple,
            $apple->provider,
        );

        $this->assertTrue(
            $google->provider_email_verified,
        );

        $this->assertCount(
            2,
            $user->socialAccounts,
        );
    }

    public function test_same_provider_identity_cannot_link_to_two_users(): void
    {
        $firstUser = User::factory()->create();
        $secondUser = User::factory()->create();

        $firstUser->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'same-google-user',
            'provider_email' => 'first@gmail.com',
            'provider_email_verified' => true,
        ]);

        $this->expectException(
            QueryException::class,
        );

        $secondUser->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'same-google-user',
            'provider_email' => 'second@gmail.com',
            'provider_email_verified' => true,
        ]);
    }

    public function test_user_cannot_link_two_accounts_from_same_provider(): void
    {
        $user = User::factory()->create();

        $user->socialAccounts()->create([
            'provider' => SocialProvider::Apple,
            'provider_user_id' => 'first-apple-user',
            'provider_email_verified' => true,
        ]);

        $this->expectException(
            QueryException::class,
        );

        $user->socialAccounts()->create([
            'provider' => SocialProvider::Apple,
            'provider_user_id' => 'second-apple-user',
            'provider_email_verified' => true,
        ]);
    }

    public function test_social_accounts_are_deleted_with_user(): void
    {
        $user = User::factory()->create();

        $socialAccount = $user->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'cascade-google-user',
            'provider_email' => 'cascade@gmail.com',
            'provider_email_verified' => true,
        ]);

        $socialAccountId = $socialAccount->id;

        $this->assertDatabaseHas(
            'social_accounts',
            [
                'id' => $socialAccountId,
            ],
        );

        $user->delete();

        $this->assertDatabaseMissing(
            'social_accounts',
            [
                'id' => $socialAccountId,
            ],
        );
    }

    public function test_sensitive_provider_identifier_is_hidden_from_json(): void
    {
        $user = User::factory()->create();

        $socialAccount = $user->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'private-provider-id',
            'provider_email' => 'safe@gmail.com',
            'provider_email_verified' => true,
        ]);

        $serialized = $socialAccount->toArray();

        $this->assertArrayNotHasKey(
            'id',
            $serialized,
        );

        $this->assertArrayNotHasKey(
            'user_id',
            $serialized,
        );

        $this->assertArrayNotHasKey(
            'provider_user_id',
            $serialized,
        );

        $this->assertArrayHasKey(
            'provider',
            $serialized,
        );
    }
}
