<?php

namespace App\Support\Localization;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use RuntimeException;
use Throwable;
use UnexpectedValueException;

final class TranslationCatalog
{
    public function load(string $requestedLocale): array
    {
        $version = (string) config(
            'soul.translations.catalog_version',
            '1',
        );

        $cacheKey = $this->cacheKey(
            $requestedLocale,
            $version,
        );

        try {
            $cached = Cache::get($cacheKey);

            if ($this->isValidCachedCatalog($cached)) {
                return $cached;
            }
        } catch (Throwable) {
            // Translation cache is an optimization, never a bootstrap dependency.
        }

        $catalog = $this->build(
            requestedLocale: $requestedLocale,
            version: $version,
        );

        try {
            Cache::forever(
                $cacheKey,
                $catalog,
            );
        } catch (Throwable) {
            // Serve the freshly built catalog even when the cache is unavailable.
        }

        return $catalog;
    }

    public function forget(string $locale): void
    {
        $version = (string) config(
            'soul.translations.catalog_version',
            '1',
        );

        try {
            Cache::forget(
                $this->cacheKey($locale, $version),
            );
        } catch (Throwable) {
            // Admin edits remain valid even when cache invalidation is unavailable.
        }
    }

    private function build(
        string $requestedLocale,
        string $version,
    ): array {
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

        if (Schema::hasTable('translation_overrides')) {
            $overrides = DB::table('translation_overrides')
                ->where('locale', $servedLocale)
                ->where('is_active', true)
                ->pluck('value', 'key')
                ->all();

            $translations = array_replace(
                $translations,
                $overrides,
            );
        }

        ksort($translations);

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

    private function cacheKey(
        string $locale,
        string $version,
    ): string {
        return 'soul:translation-catalog:'.$version.':'.$locale;
    }

    private function isValidCachedCatalog(mixed $catalog): bool
    {
        return is_array($catalog)
            && isset(
                $catalog['requested_locale'],
                $catalog['locale'],
                $catalog['fallback_locale'],
                $catalog['direction'],
                $catalog['version'],
                $catalog['hash'],
                $catalog['values'],
            )
            && is_array($catalog['values'])
            && is_string($catalog['hash'])
            && strlen($catalog['hash']) === 64;
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
