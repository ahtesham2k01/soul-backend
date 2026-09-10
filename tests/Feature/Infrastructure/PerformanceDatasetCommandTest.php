<?php

namespace Tests\Feature\Infrastructure;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PerformanceDatasetCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_generator_requires_explicit_confirmation(): void
    {
        $this->assertSame(1, Artisan::call('soul:seed-performance', ['--users' => 4, '--matches' => 2]));
        $this->assertDatabaseCount('users', 0);
    }

    public function test_generator_creates_bounded_coherent_synthetic_data(): void
    {
        $exit = Artisan::call('soul:seed-performance', [
            '--users' => 6,
            '--matches' => 3,
            '--messages' => 4,
            '--confirm' => 'GENERATE-SYNTHETIC-DATA',
        ]);

        $this->assertSame(0, $exit);
        $this->assertDatabaseCount('users', 6);
        $this->assertDatabaseCount('user_profiles', 6);
        $this->assertDatabaseCount('discovery_preferences', 6);
        $this->assertDatabaseCount('user_matches', 3);
        $this->assertDatabaseCount('conversations', 3);
        $this->assertDatabaseCount('messages', 12);
        $this->assertSame(6, DB::table('users')->where('email', 'like', 'loadtest-%@example.invalid')->count());
    }

    public function test_generator_rejects_unsafe_sizes_without_writing(): void
    {
        config()->set('soul.performance.synthetic.maximum_users', 10);
        $exit = Artisan::call('soul:seed-performance', [
            '--users' => 11,
            '--matches' => 1,
            '--confirm' => 'GENERATE-SYNTHETIC-DATA',
        ]);

        $this->assertSame(1, $exit);
        $this->assertDatabaseCount('users', 0);
    }

    public function test_capacity_probe_is_read_only_and_returns_machine_readable_results(): void
    {
        $this->assertSame(0, Artisan::call('soul:performance-check', ['--max-ms' => 60000]));
        $result = json_decode(trim(Artisan::output()), true, flags: JSON_THROW_ON_ERROR);

        $this->assertSame('healthy', $result['status']);
        $this->assertSame(60000, $result['target_ms']);
        $this->assertCount(6, $result['probes']);
        $this->assertDatabaseCount('users', 0);
    }
}
