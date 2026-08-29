<?php

namespace App\Support\Localization;

use Illuminate\Support\Facades\File;
use RuntimeException;
use UnexpectedValueException;

final class TranslationCatalog
{
    public function load(string $requestedLocale): array
    {
        $fallbackLocale = config(
            'soul.translations.fallback_locale',
            'en',
        );

        $fallbackTranslations = $this->read(
            locale: $fallbackLocale,
            required: true,
        );

        $requestedTranslations = $requestedLocale === $fallbackLocale
            ? $fallbackTranslations
            : $this->read(
                locale: $requestedLocale,
                required: false,
            );

        $servedLocale = $requestedTranslations === null
            ? $fallbackLocale
            : $requestedLocale;

        $translations = array_replace(
            $fallbackTranslations,
            $requestedTranslations ?? [],
        );

        ksort($translations);

        $version = (string) config(
            'soul.translations.catalog_version',
            '1',
        );

        $hash = hash(
            'sha256',
            json_encode(
                [
                    'locale' => $servedLocale,
                    'version' => $version,
                    'values' => $translations,
                ],
                JSON_UNESCAPED_UNICODE
                | JSON_UNESCAPED_SLASHES
                | JSON_THROW_ON_ERROR,
            ),
        );

        return [
            'requested_locale' => $requestedLocale,
            'locale' => $servedLocale,
            'fallback_locale' => $fallbackLocale,
            'direction' => config(
                "soul.translations.locales.{$servedLocale}.direction",
                'ltr',
            ),
            'version' => $version,
            'hash' => $hash,
            'values' => $translations,
        ];
    }

    private function read(
        string $locale,
        bool $required,
    ): ?array {
        if (! preg_match('/^[A-Za-z0-9-]+$/', $locale)) {
            throw new UnexpectedValueException(
                'Invalid translation locale.',
            );
        }

        $path = lang_path($locale.'.json');

        if (! File::exists($path)) {
            if ($required) {
                throw new RuntimeException(
                    "Required translation catalog [{$locale}] is missing.",
                );
            }

            return null;
        }

        $translations = json_decode(
            File::get($path),
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        if (! is_array($translations)) {
            throw new UnexpectedValueException(
                "Translation catalog [{$locale}] must contain an object.",
            );
        }

        foreach ($translations as $key => $value) {
            if (! is_string($key) || ! is_string($value)) {
                throw new UnexpectedValueException(
                    "Translation catalog [{$locale}] must use flat string values.",
                );
            }
        }

        return $translations;
    }
}
