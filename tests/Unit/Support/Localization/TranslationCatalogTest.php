<?php

namespace Tests\Unit\Support\Localization;

use App\Models\User;
use App\Support\Localization\TranslationCatalog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TranslationCatalogTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config(['cache.default' => 'array']);
        cache()->flush();
    }

    public function test_compiled_catalog_is_cached_until_locale_is_invalidated(): void
    {
        $catalog = app(TranslationCatalog::class);
        $original = $catalog->load('en');
        $originalValue = $original['values']['auth.create_account'];

        DB::table('translation_overrides')->insert([
            'locale' => 'en',
            'key' => 'auth.create_account',
            'value' => 'Create your account',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $cached = $catalog->load('en');

        $this->assertSame(
            $originalValue,
            $cached['values']['auth.create_account'],
        );

        $catalog->forget('en');

        $fresh = $catalog->load('en');

        $this->assertSame(
            'Create your account',
            $fresh['values']['auth.create_account'],
        );
        $this->assertNotSame($cached['hash'], $fresh['hash']);
    }


    public function test_invalid_cached_payload_is_ignored_and_rebuilt(): void
    {
        $version = (string) config('soul.translations.catalog_version');

        cache()->forever(
            'soul:translation-catalog:'.$version.':en',
            ['broken' => true],
        );

        $catalog = app(TranslationCatalog::class)->load('en');

        $this->assertSame('en', $catalog['locale']);
        $this->assertSame(64, strlen($catalog['hash']));
        $this->assertArrayHasKey(
            'auth.create_account',
            $catalog['values'],
        );
    }

    public function test_admin_translation_update_invalidates_compiled_catalog(): void
    {
        $catalog = app(TranslationCatalog::class);
        $before = $catalog->load('en');

        Sanctum::actingAs(
            User::factory()->create([
                'status' => User::STATUS_ACTIVE,
                'admin_role' => 'super_admin',
            ]),
        );

        $this->putJson('/api/v1/admin/catalogs/translations', [
            'locale' => 'en',
            'key' => 'auth.create_account',
            'value' => 'Join SOUL',
            'reason' => 'Approved product copy update',
        ])->assertOk();

        $after = $catalog->load('en');

        $this->assertSame(
            'Join SOUL',
            $after['values']['auth.create_account'],
        );
        $this->assertNotSame($before['hash'], $after['hash']);
    }
}
