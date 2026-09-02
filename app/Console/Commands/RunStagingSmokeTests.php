<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Throwable;

class RunStagingSmokeTests extends Command
{
    protected $signature = 'soul:smoke {--base-url= : API origin, for example https://staging.example.com}';

    protected $description = 'Run non-destructive SOUL API smoke tests against an environment';

    public function handle(): int
    {
        $origin = rtrim((string) ($this->option('base-url') ?: config('app.url')), '/');

        if (filter_var($origin, FILTER_VALIDATE_URL) === false) {
            $this->error('A valid --base-url or APP_URL is required.');

            return self::FAILURE;
        }

        $checks = [
            ['/api/v1/health', 'data.status', 'ok'],
            ['/api/v1/health/ready', 'data.status', 'ready'],
            ['/api/v1/bootstrap', 'data.brand.name', 'SOUL'],
        ];

        foreach ($checks as [$path, $jsonPath, $expected]) {
            try {
                $response = Http::acceptJson()->timeout(10)->get($origin.$path);
            } catch (Throwable) {
                $this->error("FAIL {$path}: request could not be completed.");

                return self::FAILURE;
            }

            if (! $this->valid($response, $jsonPath, $expected)) {
                $this->error("FAIL {$path}: unexpected status or response contract.");

                return self::FAILURE;
            }

            $this->info("PASS {$path}");
        }

        $this->info('SOUL non-destructive smoke tests passed.');

        return self::SUCCESS;
    }

    private function valid(Response $response, string $jsonPath, string $expected): bool
    {
        return $response->successful()
            && $response->json('success') === true
            && $response->json($jsonPath) === $expected
            && filled($response->header('X-Request-ID'));
    }
}
