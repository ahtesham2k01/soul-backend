<?php

namespace Tests\Feature\Api\V1\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class AdminSessionBoundaryTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_sign_in_with_a_browser_session_and_open_the_admin_api(): void
    {
        $admin = $this->admin();

        $response = $this->post('/admin/session', [
            'email' => $admin->email,
            'password' => 'password',
        ]);

        $response->assertRedirect('/admin');
        $response->assertCookieMissing(Auth::guard()->getRecallerName());

        $this->getJson('/api/v1/admin/dashboard')->assertOk();
    }

    public function test_mobile_bearer_token_cannot_cross_the_admin_session_boundary(): void
    {
        $admin = $this->admin();
        $token = $admin->createToken('flutter-device', ['mobile'])->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/v1/admin/dashboard')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'ADMIN_SESSION_REQUIRED');

        $this->assertNull($admin->tokens()->sole()->last_used_at);
    }

    public function test_suspended_admin_cannot_create_a_browser_session(): void
    {
        $admin = $this->admin();
        $admin->forceFill(['status' => User::STATUS_SUSPENDED])->save();

        $this->from('/admin')->post('/admin/session', [
            'email' => $admin->email,
            'password' => 'password',
        ])->assertRedirect('/admin')->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_member_browser_session_still_cannot_access_admin_endpoints(): void
    {
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);

        $this->actingAs($member)
            ->getJson('/api/v1/admin/dashboard')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ADMIN_ACCESS_DENIED');
    }

    public function test_every_admin_api_route_keeps_the_session_boundary_and_authentication(): void
    {
        $routes = collect(Route::getRoutes()->getRoutes())
            ->filter(fn ($route): bool => str_starts_with((string) $route->getName(), 'api.v1.admin.'));

        $this->assertNotEmpty($routes);

        $routes->each(function ($route): void {
            $middleware = $route->gatherMiddleware();

            $this->assertContains('admin.session', $middleware, $route->getName().' is missing the admin session boundary.');
            $this->assertContains('auth:sanctum', $middleware, $route->getName().' is missing authentication.');
        });
    }

    private function admin(): User
    {
        $admin = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $admin->forceFill(['admin_role' => 'moderator'])->save();

        return $admin;
    }
}
