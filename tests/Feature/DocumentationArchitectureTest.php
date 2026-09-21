<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\File;
use Tests\TestCase;

class DocumentationArchitectureTest extends TestCase
{
    public function test_single_master_document_covers_every_audience_and_domain(): void
    {
        $path = base_path('docs/SOUL_V1_MASTER_DOCUMENTATION.md');
        $this->assertFileExists($path);
        $contents = File::get($path);

        foreach ([
            '## How to use this document', '## Executive summary', '## Product requirements',
            '## Backend scope and implementation status', '## Delivery progress',
            '## Complete member app flow', '## Flutter developer guide',
            '## Flutter API reference', '## Database design', '## Localization',
            '## React admin operations', '## Production readiness',
            '## Release closure', '## PRD traceability',
        ] as $section) {
            $this->assertStringContainsString($section, $contents, "Missing [{$section}] from the master documentation.");
        }

        foreach (['Product owner or stakeholder', 'Investor or business partner', 'Flutter developer', 'Backend developer', 'Admin/operator', 'QA/release engineer'] as $audience) {
            $this->assertStringContainsString($audience, $contents);
        }
    }

    public function test_master_document_contains_all_gap_closure_phases(): void
    {
        $contents = File::get(base_path('docs/SOUL_V1_MASTER_DOCUMENTATION.md'));

        foreach (range(12, 27) as $phase) {
            $this->assertStringContainsString("Phase {$phase} —", $contents);
        }
    }

    public function test_final_audit_roadmap_and_flutter_handoff_remain_current(): void
    {
        $contents = File::get(base_path('docs/SOUL_V1_MASTER_DOCUMENTATION.md'));

        foreach (range(35, 41) as $phase) {
            $this->assertStringContainsString("Phase {$phase} —", $contents);
        }

        $this->assertStringContainsString(
            '- [x] Phase 36 — Typed Flutter requests/responses',
            $contents,
        );
    }


    public function test_member_app_readme_preserves_checked_in_native_runners(): void
    {
        $contents = File::get(base_path('apps/member_app/README.md'));

        $this->assertStringContainsString('Android and iOS runners are version-controlled', $contents);
        $this->assertStringContainsString('Do **not** run `flutter create`', $contents);
        $this->assertStringContainsString('flutter analyze', $contents);
        $this->assertStringContainsString('flutter test', $contents);
        $this->assertStringContainsString('SOUL_API_ORIGIN', $contents);
    }

    public function test_every_numbered_prd_section_has_traceability_evidence(): void
    {
        $contents = File::get(base_path('docs/SOUL_V1_MASTER_DOCUMENTATION.md'));
        preg_match_all('/^### (\d+)\. (.+)$/m', $contents, $matches, PREG_SET_ORDER);
        $requirements = array_slice($matches, 0, 23);
        $this->assertCount(23, $requirements);

        foreach ($requirements as $requirement) {
            $this->assertStringContainsString("| {$requirement[1]}. {$requirement[2]} |", $contents);
        }
    }

    public function test_master_document_tracks_generated_member_contract_count_and_current_profile_fields(): void
    {
        $contents = File::get(base_path('docs/SOUL_V1_MASTER_DOCUMENTATION.md'));
        $manifest = json_decode(
            File::get(base_path('docs/contracts/flutter-v1.json')),
            true,
            flags: JSON_THROW_ON_ERROR,
        );
        $endpointCount = $manifest['endpointCount'];

        $this->assertSame($endpointCount, count($manifest['endpoints']));
        $this->assertStringContainsString(
            "generated {$endpointCount}-endpoint member catalog",
            $contents,
        );
        $this->assertStringContainsString(
            "complete {$endpointCount}-endpoint member surface",
            $contents,
        );
        $this->assertStringNotContainsString('spoken_language_ids', $contents);
        $this->assertStringContainsString('spoken_language_codes', $contents);
        $this->assertStringContainsString('admin-managed profile catalogs', $contents);
    }

    public function test_machine_readable_contracts_remain_separate_and_importable(): void
    {
        foreach (['docs/contracts/openapi-v1.json', 'docs/contracts/postman-v1.collection.json', 'docs/contracts/flutter-v1.json'] as $path) {
            $this->assertFileExists(base_path($path));
            $this->assertIsArray(json_decode(File::get(base_path($path)), true, flags: JSON_THROW_ON_ERROR));
        }

        foreach (['docs/contracts/soul_v1_api.dart', 'docs/contracts/soul_v1_models.dart'] as $path) {
            $this->assertFileExists(base_path($path));
            $this->assertNotEmpty(File::get(base_path($path)));
        }

        $fixtures = File::files(base_path('docs/contracts/fixtures'));
        $this->assertGreaterThanOrEqual(10, count($fixtures));

        foreach ($fixtures as $fixture) {
            $payload = json_decode($fixture->getContents(), true, flags: JSON_THROW_ON_ERROR);
            $this->assertIsArray($payload);
            $this->assertArrayHasKey('success', $payload);
            $this->assertArrayHasKey('meta', $payload);
            $this->assertArrayHasKey('request_id', $payload['meta']);
        }
    }

    public function test_every_migration_has_an_explicit_rollback_method(): void
    {
        $migrations = File::files(database_path('migrations'));
        $this->assertNotEmpty($migrations);

        foreach ($migrations as $migration) {
            $this->assertStringContainsString(
                'function down(', $migration->getContents(),
                "Migration [{$migration->getFilename()}] has no explicit rollback method.",
            );
        }
    }
}
