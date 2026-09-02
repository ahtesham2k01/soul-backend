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
            'docs/APP_FLOW.md' => ['## Onboarding screens', '## Discovery flow', '## Safety flow', '## Events flow', '## Subscription flow'],
            'docs/DATABASE_DESIGN.md' => ['## Current domain map', '## Current tables by ownership', '## Planned V1 schema extensions'],
            'docs/BACKEND_SCOPE.md' => ['## Current implemented foundation', '## Gap-closure phases', '## Definition of complete'],
            'docs/DOCUMENTATION_INDEX.md' => ['FLUTTER_API_HANDOFF.md', 'openapi-v1.json', 'SOUL_V1_BACKEND_PROGRESS.md'],
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
}
