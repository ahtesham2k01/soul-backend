<?php

namespace Tests\Feature\Models;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class UserModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_receives_public_ulid_and_safe_defaults(): void
    {
        $user = User::query()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'secure-password',
            'preferred_locale' => 'en',
        ]);

        $user->refresh();

        $this->assertNotNull(
            $user->public_id,
        );

        $this->assertTrue(
            Str::isUlid($user->public_id),
        );

        $this->assertSame(
            User::STATUS_ACTIVE,
            $user->status,
        );

        $this->assertSame(
            'en',
            $user->preferred_locale,
        );

        $this->assertSame(
            'public_id',
            $user->getRouteKeyName(),
        );

        $this->assertNull(
            $user->last_login_at,
        );

        $this->assertNull(
            $user->onboarding_completed_at,
        );
    }

    public function test_password_is_hashed_automatically(): void
    {
        $plainPassword = 'secure-password';

        $user = User::query()->create([
            'name' => 'Password User',
            'email' => 'password@example.com',
            'password' => $plainPassword,
        ]);

        $this->assertNotSame(
            $plainPassword,
            $user->password,
        );

        $this->assertTrue(
            Hash::check(
                $plainPassword,
                $user->password,
            ),
        );
    }

    public function test_sensitive_internal_fields_are_hidden_from_json(): void
    {
        $user = User::query()->create([
            'name' => 'Safe User',
            'email' => 'safe@example.com',
            'password' => 'secure-password',
        ]);

        $serialized = $user->toArray();

        $this->assertArrayHasKey(
            'public_id',
            $serialized,
        );

        $this->assertArrayNotHasKey(
            'id',
            $serialized,
        );

        $this->assertArrayNotHasKey(
            'password',
            $serialized,
        );

        $this->assertArrayNotHasKey(
            'remember_token',
            $serialized,
        );
    }

    public function test_email_phone_and_password_can_be_nullable_for_social_login(): void
    {
        $user = User::query()->create([
            'name' => null,
            'email' => null,
            'phone' => null,
            'password' => null,
            'preferred_locale' => 'en',
        ]);

        $user->refresh();

        $this->assertNull(
            $user->name,
        );

        $this->assertNull(
            $user->email,
        );

        $this->assertNull(
            $user->phone,
        );

        $this->assertNull(
            $user->password,
        );

        $this->assertTrue(
            Str::isUlid($user->public_id),
        );
    }
}
