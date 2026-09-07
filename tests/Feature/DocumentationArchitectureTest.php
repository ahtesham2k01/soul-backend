<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\File;
use Tests\TestCase;

class DocumentationArchitectureTest extends TestCase
{
    public function test_complete_product_and_engineering_handoff_documents_exist(): void
    {
        $documents = [
            'docs/Soul_V1_Product_Requirements.md' => ['## 1. Product scope', '## 18. Subscription and dynamic entitlements', '## 23. Implementation principles'],
            'docs/FLUTTER_DEVELOPER_GUIDE.md' => ['## Client architecture', '## Localization contract', '## Release checklist for Flutter'],
            'docs/LOCALIZATION_GUIDE.md' => ['## Flutter: load translations', '## React admin', '## Add a new translation'],
            'docs/PROFILE_INFORMATION_CONTRACT.md' => ['## Endpoints and save behavior', '## Required fields', '## Optional fields and limits', '## Skip versus prefer not to say'],
            'docs/RELIGION_DISCOVERY_CONTRACT.md' => ['## Product rule', '## Data flow', '## Flutter API usage', '## Important errors'],
            'docs/DISCOVERY_PRIVACY_CONTRACT.md' => ['## Discovery preferences', '## Eligibility and ranking', '## Distance privacy', '## Contact privacy'],
            'docs/PRIVATE_PHOTO_CONTRACT.md' => ['## Product rules', '## Request and approval flow', '## Secure media delivery', '## Screenshot protection'],
            'docs/LIKE_MATCH_CHAT_CONTRACT.md' => ['## Product rules', '## Like request flow', '## Match and conversation flow', '## Presence and typing'],
            'docs/MARITAL_STATUS_CONTRACT.md' => ['## Product rules', '## Discovery card', '## Full profile', '## Flutter checklist'],
            'docs/EVENTS_CONTRACT.md' => ['## Member flow', '## Privacy and online links', '## Localization', '## Admin flow'],
            'docs/APP_FLOW.md' => ['## Onboarding screens', '## Discovery flow', '## Safety flow', '## Events flow', '## Subscription flow'],
            'docs/DATABASE_DESIGN.md' => ['## Current domain map', '## Current tables by ownership', '## Planned V1 schema extensions'],
            'docs/BACKEND_SCOPE.md' => ['## Current implemented foundation', '## Gap-closure phases', '## Definition of complete'],
            'docs/DOCUMENTATION_INDEX.md' => ['FLUTTER_API_HANDOFF.md', 'openapi-v1.json', 'SOUL_V1_BACKEND_PROGRESS.md'],
            'docs/PRD_TRACEABILITY_MATRIX.md' => ['1. Product scope', '22. Explicitly deferred decisions', '23. Implementation principles'],
            'docs/RELEASE_CLOSURE.md' => ['## Completed release-candidate evidence', '## Staging gates before approval', '## Authenticated staging journeys'],
        ];

        foreach ($documents as $path => $requiredSections) {
            $this->assertFileExists(base_path($path));
            $contents = File::get(base_path($path));

            foreach ($requiredSections as $section) {
                $this->assertStringContainsString($section, $contents, "Missing [{$section}] from [{$path}].");
            }
        }
    }

    public function test_backend_scope_and_progress_use_the_same_gap_closure_phases(): void
    {
        $scope = File::get(base_path('docs/BACKEND_SCOPE.md'));
        $progress = File::get(base_path('SOUL_V1_BACKEND_PROGRESS.md'));

        foreach (range(12, 27) as $phase) {
            $this->assertStringContainsString("Phase {$phase} —", $scope);
            $this->assertStringContainsString("Phase {$phase} —", $progress);
        }
    }

    public function test_every_numbered_prd_section_has_traceability_evidence(): void
    {
        $requirements = File::get(base_path('docs/Soul_V1_Product_Requirements.md'));
        $matrix = File::get(base_path('docs/PRD_TRACEABILITY_MATRIX.md'));

        preg_match_all('/^## (\d+)\. (.+)$/m', $requirements, $matches, PREG_SET_ORDER);

        $this->assertCount(23, $matches);

        foreach ($matches as $match) {
            $this->assertStringContainsString("| {$match[1]}. {$match[2]} |", $matrix);
        }
    }

    public function test_every_migration_has_an_explicit_rollback_method(): void
    {
        $migrations = File::files(database_path('migrations'));

        $this->assertNotEmpty($migrations);

        foreach ($migrations as $migration) {
            $this->assertStringContainsString(
                'function down(',
                $migration->getContents(),
                "Migration [{$migration->getFilename()}] has no explicit rollback method.",
            );
        }
    }
}
