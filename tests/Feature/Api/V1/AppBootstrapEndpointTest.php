<?php

namespace Tests\Feature\Api\V1;

use Tests\TestCase;

class AppBootstrapEndpointTest extends TestCase
{
    public function test_bootstrap_returns_flutter_friendly_contract(): void
    {
        $response = $this->getJson(
            '/api/v1/bootstrap?locale=en',
        );

        $requestId = $response->headers->get(
            'X-Request-ID',
        );

        $response
            ->assertOk()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath('success', true)
            ->assertJsonPath(
                'message',
                'App bootstrap loaded successfully.',
            )
            ->assertJsonPath(
                'data.brand.name',
                'SOUL',
            )
            ->assertJsonPath(
                'data.brand.translate',
                false,
            )
            ->assertJsonPath(
                'data.locale.requested',
                'en',
            )
            ->assertJsonPath(
                'data.locale.matched',
                'en',
            )
            ->assertJsonPath(
                'data.locale.resolved',
                'en',
            )
            ->assertJsonPath(
                'data.locale.fallback',
                'en',
            )
            ->assertJsonPath(
                'data.locale.direction',
                'ltr',
            )
            ->assertJsonPath(
                'data.translations.version',
                '1',
            )
            ->assertJsonPath(
                'data.supported_languages.0.code',
                'en',
            )
            ->assertJsonPath(
                'data.location',
                null,
            )
            ->assertJsonPath(
                'data.location_status',
                'unresolved',
            )
            ->assertJsonPath(
                'meta.request_id',
                $requestId,
            );

        /*
         * Translation keys contain dots and are flat keys.
         * assertJsonPath would treat dots as nested paths,
         * so assertJsonFragment is used instead.
         */
        $response->assertJsonFragment([
            'auth.create_account' => 'Create Account',
        ]);

        $response->assertJsonFragment([
            'onboarding.headline_highlight' => 'Swipe to Your',
        ]);

        $hash = $response->json(
            'data.translations.hash',
        );

        $this->assertIsString($hash);
        $this->assertSame(64, strlen($hash));
    }

    public function test_query_locale_has_priority_over_header(): void
    {
        $response = $this
            ->withHeader(
                'Accept-Language',
                'fr-FR',
            )
            ->getJson(
                '/api/v1/bootstrap?locale=ur-PK',
            );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.locale.requested',
                'ur-PK',
            )
            ->assertJsonPath(
                'data.locale.matched',
                'ur',
            )
            ->assertJsonPath(
                'data.locale.resolved',
                'en',
            );
    }

    public function test_accept_language_is_used_without_query_locale(): void
    {
        $response = $this
            ->withHeader(
                'Accept-Language',
                'fr-FR;q=0.5, es-MX;q=0.9',
            )
            ->getJson('/api/v1/bootstrap');

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.locale.matched',
                'es',
            )
            ->assertJsonPath(
                'data.locale.resolved',
                'en',
            );
    }

    public function test_unsupported_locale_falls_back_to_english(): void
    {
        $response = $this->getJson(
            '/api/v1/bootstrap?locale=xx-ZZ',
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.locale.requested',
                'xx-ZZ',
            )
            ->assertJsonPath(
                'data.locale.matched',
                'en',
            )
            ->assertJsonPath(
                'data.locale.resolved',
                'en',
            )
            ->assertJsonPath(
                'data.locale.direction',
                'ltr',
            );
    }
}
