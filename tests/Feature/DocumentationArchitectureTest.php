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

    public function test_machine_readable_contracts_remain_separate_and_importable(): void
    {
        foreach (['docs/contracts/openapi-v1.json', 'docs/contracts/postman-v1.collection.json'] as $path) {
            $this->assertFileExists(base_path($path));
            $this->assertIsArray(json_decode(File::get(base_path($path)), true, flags: JSON_THROW_ON_ERROR));
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
