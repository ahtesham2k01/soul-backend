<?php

namespace Tests\Feature\Support\Localization;

use JsonException;
use Tests\TestCase;

class TranslationCatalogCompletenessTest extends TestCase
{
    /**
     * @throws JsonException
     */
    public function test_every_configured_locale_has_a_complete_valid_catalog(): void
    {
        $configuredLocales = config(
            'soul.translations.locales',
            [],
        );

        $this->assertNotEmpty(
            $configuredLocales,
            'No translation locales are configured.',
        );

        $englishCatalog = $this->readCatalog('en');
        $englishKeys = array_keys($englishCatalog);

        sort($englishKeys);

        $this->assertNotEmpty(
            $englishKeys,
            'The English translation catalog is empty.',
        );

        $this->assertArrayNotHasKey(
            'brand.name',
            $englishCatalog,
            'SOUL must not be stored as a translatable brand name.',
        );

        foreach ($configuredLocales as $locale => $metadata) {
            $this->assertContains(
                $metadata['direction'] ?? null,
                ['ltr', 'rtl'],
                "Locale [{$locale}] must use ltr or rtl direction.",
            );

            $catalog = $this->readCatalog($locale);
            $catalogKeys = array_keys($catalog);

            sort($catalogKeys);

            $this->assertSame(
                $englishKeys,
                $catalogKeys,
                "Locale [{$locale}] does not contain exactly the same keys as English.",
            );

            $this->assertArrayNotHasKey(
                'brand.name',
                $catalog,
                "Locale [{$locale}] must not translate the SOUL brand name.",
            );

            foreach ($catalog as $key => $value) {
                $this->assertIsString(
                    $value,
                    "Translation [{$locale}.{$key}] must be a string.",
                );

                $this->assertNotSame(
                    '',
                    trim($value),
                    "Translation [{$locale}.{$key}] must not be empty.",
                );
            }
        }
    }

    public function test_english_and_roman_urdu_cover_every_v1_feature_area(): void
    {
        $english = $this->readCatalog('en');
        $urdu = $this->readCatalog('ur');
        $requiredPrefixes = ['auth.', 'nav.', 'profile.', 'photos.', 'onboarding.', 'discovery.', 'matches.', 'chat.', 'safety.', 'notifications.', 'settings.', 'admin.'];

        foreach ($requiredPrefixes as $prefix) {
            $this->assertNotEmpty(
                array_filter(array_keys($english), fn (string $key): bool => str_starts_with($key, $prefix)),
                "English catalog is missing the [{$prefix}] feature area.",
            );
            $this->assertNotEmpty(
                array_filter(array_keys($urdu), fn (string $key): bool => str_starts_with($key, $prefix)),
                "Roman Urdu catalog is missing the [{$prefix}] feature area.",
            );
        }

        foreach (['common.continue', 'auth.create_account', 'profile.intentions', 'settings.deletion_recovery', 'admin.authorized_only'] as $key) {
            $this->assertNotSame($english[$key], $urdu[$key], "Roman Urdu key [{$key}] must not silently fall back to English.");
        }

        $this->assertGreaterThanOrEqual(225, count($english));
    }

    public function test_react_admin_uses_the_laravel_catalog_instead_of_a_second_dictionary(): void
    {
        $admin = file_get_contents(resource_path('js/admin.tsx'));

        $this->assertNotFalse($admin);
        $this->assertStringContainsString("fetch('/api/v1/bootstrap?locale='", $admin);
        $this->assertStringContainsString("localStorage.getItem('soul.admin.locale')", $admin);
        $this->assertStringContainsString('document.documentElement.dir=result.data.locale.direction', $admin);
        $this->assertStringContainsString("t('admin.user_directory')", $admin);
        $this->assertStringNotContainsString('Authorized team members only.', $admin);
        $this->assertStringNotContainsString('Reason for this decision:', $admin);

        preg_match_all("/t\\('([^']+)'\\)/", $admin, $matches);
        $english = $this->readCatalog('en');
        $urdu = $this->readCatalog('ur');

        foreach (array_unique($matches[1]) as $key) {
            if (! str_starts_with($key, 'admin.') && ! str_starts_with($key, 'common.')) {
                continue;
            }

            $this->assertArrayHasKey($key, $english, "React admin key [{$key}] is missing from English.");
            $this->assertArrayHasKey($key, $urdu, "React admin key [{$key}] is missing from Roman Urdu.");
        }
    }

    /**
     * @return array<string, string>
     *
     * @throws JsonException
     */
    private function readCatalog(string $locale): array
    {
        $path = lang_path(
            "{$locale}.json",
        );

        $this->assertFileExists(
            $path,
            "Translation catalog [{$locale}] is missing.",
        );

        $contents = file_get_contents($path);

        $this->assertNotFalse(
            $contents,
            "Translation catalog [{$locale}] could not be read.",
        );

        $catalog = json_decode(
            $contents,
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        $this->assertIsArray(
            $catalog,
            "Translation catalog [{$locale}] must contain a JSON object.",
        );

        return $catalog;
    }
}
