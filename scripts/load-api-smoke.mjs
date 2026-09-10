#!/usr/bin/env node

const args = new Set(process.argv.slice(2));
if (args.has('--help')) {
    console.log('SOUL load smoke: BASE_URL=http://127.0.0.1:8000 REQUESTS=100 CONCURRENCY=10 node scripts/load-api-smoke.mjs');
    console.log('Non-local targets require SOUL_LOAD_TEST_APPROVED=1. Optional API_TOKEN adds an authenticated /api/v1/me journey.');
    process.exit(0);
}

const baseUrl = new URL(process.env.BASE_URL || 'http://127.0.0.1:8000');
const localHosts = new Set(['127.0.0.1', 'localhost', '::1']);
if (!localHosts.has(baseUrl.hostname) && process.env.SOUL_LOAD_TEST_APPROVED !== '1') {
    throw new Error('Refusing to load-test a non-local target without SOUL_LOAD_TEST_APPROVED=1.');
}

const total = Math.max(1, Math.min(10000, Number(process.env.REQUESTS || 100)));
const concurrency = Math.max(1, Math.min(100, Number(process.env.CONCURRENCY || 10)));
const maxP95 = Math.max(1, Number(process.env.MAX_P95_MS || 1000));
const token = process.env.API_TOKEN;
const journeys = ['/api/v1/health', '/api/v1/bootstrap?locale=en'];
if (token) journeys.push('/api/v1/me');
const durations = [];
let next = 0;
let failures = 0;

async function worker() {
    while (next < total) {
        const index = next++;
        const started = performance.now();
        try {
            const response = await fetch(new URL(journeys[index % journeys.length], baseUrl), {
                headers: token ? { Authorization: `Bearer ${token}` } : {},
                signal: AbortSignal.timeout(10000),
            });
            if (!response.ok) failures++;
            await response.arrayBuffer();
        } catch {
            failures++;
        }
        durations.push(performance.now() - started);
    }
}

await Promise.all(Array.from({ length: concurrency }, worker));
durations.sort((a, b) => a - b);
const percentile = p => durations[Math.min(durations.length - 1, Math.ceil(durations.length * p) - 1)];
const result = { requests: total, concurrency, failures, error_rate: failures / total, p50_ms: Math.round(percentile(.5)), p95_ms: Math.round(percentile(.95)), p99_ms: Math.round(percentile(.99)) };
console.log(JSON.stringify(result));
if (result.error_rate > .01 || result.p95_ms > maxP95) process.exitCode = 1;
