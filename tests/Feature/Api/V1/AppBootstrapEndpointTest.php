<?php

namespace Tests\Feature\Api\V1;

use App\Contracts\Location\GeolocationProvider;
use App\Data\LocationData;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AppBootstrapEndpointTest extends TestCase
{
    use RefreshDatabase;
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
                '20',
            )
            ->assertJsonFragment([
                'auth.create_account' => 'Create Account',
            ])
            ->assertJsonFragment([
                'code' => 'en',
                'name' => 'English',
                'native_name' => 'English',
                'direction' => 'ltr',
                'is_launch_target' => true,
                'is_launch_ready' => true,
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

    public function test_authenticated_bootstrap_includes_current_legal_versions(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['mobile']);

        $response = $this->getJson('/api/v1/bootstrap?locale=en');

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.legal.versions.terms',
                (string) config('soul.legal.terms_version'),
            )
            ->assertJsonPath(
                'data.legal.versions.privacy',
                (string) config('soul.legal.privacy_version'),
            )
            ->assertJsonPath(
                'data.legal.versions.community_guidelines',
                (string) config('soul.legal.community_guidelines_version'),
            )
            ->assertJsonPath(
                'data.legal.versions.community_commitment',
                (string) config('soul.legal.commitment_version'),
            );
    }

    public function test_bootstrap_omits_translation_values_when_client_hash_matches(): void
    {
        $initial = $this->getJson('/api/v1/bootstrap?locale=en')
            ->assertOk();

        $hash = $initial->json('data.translations.hash');

        $response = $this->getJson(
            '/api/v1/bootstrap?locale=en&translations_hash='.$hash,
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.translations.hash', $hash)
            ->assertJsonPath('data.translations.not_modified', true)
            ->assertJsonPath('data.translations.values', null);
    }

    public function test_bootstrap_returns_translation_values_when_hash_is_stale(): void
    {
        $response = $this->getJson(
            '/api/v1/bootstrap?locale=en&translations_hash='.str_repeat('0', 64),
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.translations.not_modified', false)
            ->assertJsonFragment([
                'auth.create_account' => 'Create Account',
            ]);
    }

    public function test_bootstrap_identifies_product_target_and_draft_locales(): void
    {
        $languages = collect(
            $this->getJson('/api/v1/bootstrap?locale=en')
                ->assertOk()
                ->json('data.supported_languages'),
        )->keyBy('code');

        $expectedTargetLocales = config('soul.translations.target_locales');
        $actualTargetLocales = $languages->filter(
            fn (array $language): bool => $language['is_launch_target'],
        )->keys()->values()->all();

        sort($expectedTargetLocales);
        sort($actualTargetLocales);

        $this->assertSame($expectedTargetLocales, $actualTargetLocales);

        $this->assertTrue($languages['ur']['is_launch_ready']);
        $this->assertSame('ltr', $languages['ur']['direction']);
        $this->assertFalse($languages['ar']['is_launch_ready']);
        $this->assertSame('rtl', $languages['ar']['direction']);
        $this->assertSame('rtl', $languages['fa']['direction']);
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
                '20',
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
                '20',
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
