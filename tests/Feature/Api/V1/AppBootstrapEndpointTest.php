<?php

namespace Tests\Feature\Api\V1;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;
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
            ->assertJsonPath(
                'success',
                true,
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
                'data.locale.direction',
                'ltr',
            )
            ->assertJsonPath(
                'data.translations.version',
                '6',
            )
            ->assertJsonFragment([
                'auth.create_account' => 'Create Account',
            ])
            ->assertJsonFragment([
                'code' => 'en',
                'name' => 'English',
                'native_name' => 'English',
                'direction' => 'ltr',
            ])
            ->assertJsonPath(
                'data.location',
                null,
            )
            ->assertJsonPath(
                'data.location_status',
                'unavailable',
            )
            ->assertJsonPath(
                'meta.request_id',
                $requestId,
            );

        $hash = $response->json(
            'data.translations.hash',
        );

        $this->assertIsString($hash);

        $this->assertSame(
            64,
            strlen($hash),
        );

        $supportedLanguages = $response->json(
            'data.supported_languages',
        );

        $this->assertIsArray(
            $supportedLanguages,
        );

        $this->assertCount(
            count(
                config(
                    'soul.translations.locales',
                    [],
                ),
            ),
            $supportedLanguages,
        );
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
            );
    }

    public function test_accept_language_is_used_without_query_locale(): void
    {
        $response = $this
            ->withHeader(
                'Accept-Language',
                'fr-FR;q=0.5, es-MX;q=0.9',
            )
            ->getJson(
                '/api/v1/bootstrap',
            );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.locale.matched',
                'es',
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
                'data.locale.matched',
                'en',
            )
            ->assertJsonPath(
                'data.locale.resolved',
                'en',
            );
    }

    public function test_bootstrap_includes_location_returned_by_provider(): void
    {
        $provider = new class implements GeolocationProvider
        {
            public function fromCoordinates(
                float $latitude,
                float $longitude,
            ): ?LocationData {
                return null;
            }

            public function fromIp(
                string $ipAddress,
            ): ?LocationData {
                return new LocationData(
                    city: 'Dubai',
                    region: 'Dubai',
                    country: 'United Arab Emirates',
                    countryCode: 'AE',
                    latitude: 25.2048,
                    longitude: 55.2708,
                    timezone: 'Asia/Dubai',
                    source: 'ip',
                    isApproximate: true,
                );
            }
        };

        $this->app->instance(
            GeolocationProvider::class,
            $provider,
        );

        $response = $this->getJson(
            '/api/v1/bootstrap?locale=en',
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.location.city',
                'Dubai',
            )
            ->assertJsonPath(
                'data.location.region',
                'Dubai',
            )
            ->assertJsonPath(
                'data.location.country',
                'United Arab Emirates',
            )
            ->assertJsonPath(
                'data.location.country_code',
                'AE',
            )
            ->assertJsonPath(
                'data.location.latitude',
                25.2048,
            )
            ->assertJsonPath(
                'data.location.longitude',
                55.2708,
            )
            ->assertJsonPath(
                'data.location.timezone',
                'Asia/Dubai',
            )
            ->assertJsonPath(
                'data.location.source',
                'ip',
            )
            ->assertJsonPath(
                'data.location.is_approximate',
                true,
            )
            ->assertJsonPath(
                'data.location_status',
                'resolved',
            );
    }

    public function test_roman_urdu_catalog_is_returned_with_ltr_direction(): void
    {
        $response = $this->getJson(
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
                'ur',
            )
            ->assertJsonPath(
                'data.locale.direction',
                'ltr',
            )
            ->assertJsonPath(
                'data.translations.version',
                '6',
            )
            ->assertJsonFragment([
                'auth.create_account' => 'Account banayein',
            ])
            ->assertJsonFragment([
                'language.select' => 'Language select karein',
            ])
            ->assertJsonFragment([
                'code' => 'ur',
                'name' => 'Roman Urdu',
                'native_name' => 'Roman Urdu',
                'direction' => 'ltr',
            ]);
    }

    public function test_spanish_catalog_is_returned_for_regional_locale(): void
    {
        $response = $this->getJson(
            '/api/v1/bootstrap?locale=es-MX',
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.locale.requested',
                'es-MX',
            )
            ->assertJsonPath(
                'data.locale.matched',
                'es',
            )
            ->assertJsonPath(
                'data.locale.resolved',
                'es',
            )
            ->assertJsonPath(
                'data.locale.direction',
                'ltr',
            )
            ->assertJsonPath(
                'data.translations.version',
                '6',
            )
            ->assertJsonFragment([
                'auth.create_account' => 'Crear una cuenta',
            ])
            ->assertJsonFragment([
                'language.select' => 'Seleccionar idioma',
            ])
            ->assertJsonFragment([
                'code' => 'es',
                'name' => 'Spanish',
                'native_name' => 'Español',
                'direction' => 'ltr',
            ]);
    }
}
