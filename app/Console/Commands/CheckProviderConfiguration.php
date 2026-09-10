<?php

namespace App\Console\Commands;

use App\Support\Release\ReleaseConfigurationValidator;
use Illuminate\Console\Command;

class CheckProviderConfiguration extends Command
{
    protected $signature = 'soul:provider-check {--json : Return machine-readable, secret-free JSON}';

    protected $description = 'Validate external-provider configuration without contacting providers or exposing secrets';

    public function handle(ReleaseConfigurationValidator $validator): int
    {
        $providers = $validator->providerReadiness();

        if ($this->option('json')) {
            $this->line(json_encode($providers, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES));
        } else {
            $this->table(['Provider', 'Status', 'Missing', 'Invalid'], collect($providers)->map(
                fn (array $state, string $provider): array => [
                    $provider,
                    $state['ready'] ? 'READY' : 'BLOCKED',
                    implode(', ', $state['missing']),
                    implode(', ', $state['invalid']),
                ],
            )->values()->all());
        }

        return collect($providers)->every(fn (array $state): bool => $state['ready'])
            ? self::SUCCESS
            : self::FAILURE;
    }
}
