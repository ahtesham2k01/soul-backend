<?php

namespace App\Console\Commands;

use App\Support\Release\ReleaseConfigurationValidator;
use Illuminate\Console\Command;

class CheckReleaseConfiguration extends Command
{
    protected $signature = 'soul:config-check {--production : Enforce production-only requirements}';

    protected $description = 'Validate SOUL release configuration without exposing secret values';

    public function handle(ReleaseConfigurationValidator $validator): int
    {
        $checks = $validator->validate((bool) $this->option('production'));

        $this->table(
            ['Check', 'Status', 'Result'],
            collect($checks)->map(fn (array $check): array => [
                $check['name'],
                strtoupper($check['status']),
                $check['message'],
            ])->all(),
        );

        if (! $validator->passes($checks)) {
            $this->error('SOUL release configuration is not ready.');

            return self::FAILURE;
        }

        $this->info('SOUL release configuration is ready.');

        return self::SUCCESS;
    }
}
