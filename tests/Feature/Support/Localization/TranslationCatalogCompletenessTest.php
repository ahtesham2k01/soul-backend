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
