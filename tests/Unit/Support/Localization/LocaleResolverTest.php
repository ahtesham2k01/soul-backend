<?php

namespace Tests\Unit\Support\Localization;

use App\Support\Localization\LocaleResolver;
use Tests\TestCase;

class LocaleResolverTest extends TestCase
{
    private LocaleResolver $resolver;

    protected function setUp(): void
    {
        parent::setUp();

        $this->resolver = new LocaleResolver();
    }

    public function test_it_resolves_regional_urdu_to_urdu(): void
    {
        $locale = $this->resolver->resolve('ur-PK');

        $this->assertSame('ur', $locale);
    }

    public function test_it_resolves_regional_spanish_to_spanish(): void
    {
        $locale = $this->resolver->resolve('es-MX');

        $this->assertSame('es', $locale);
    }

    public function test_it_resolves_traditional_chinese_alias(): void
    {
        $locale = $this->resolver->resolve('zh-Hant');

        $this->assertSame('zh-TW', $locale);
    }

    public function test_explicit_locale_has_priority_over_header(): void
    {
        $locale = $this->resolver->resolve(
            requestedLocale: 'fr-FR',
            acceptLanguage: 'ur-PK',
        );

        $this->assertSame('fr', $locale);
    }

    public function test_accept_language_quality_is_respected(): void
    {
        $locale = $this->resolver->resolve(
            requestedLocale: null,
            acceptLanguage: 'fr-FR;q=0.5, ur-PK;q=0.9',
        );

        $this->assertSame('ur', $locale);
    }

    public function test_unsupported_locale_uses_english_fallback(): void
    {
        $locale = $this->resolver->resolve('xx-ZZ');

        $this->assertSame('en', $locale);
    }
}
