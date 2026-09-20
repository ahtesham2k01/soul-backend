import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const root = path.resolve(import.meta.dirname, '..');
const contracts = path.join(root, 'docs/contracts');
const manifest = JSON.parse(fs.readFileSync(path.join(contracts, 'flutter-v1.json'), 'utf8'));
const openapi = JSON.parse(fs.readFileSync(path.join(contracts, 'openapi-v1.json'), 'utf8'));
const dart = fs.readFileSync(path.join(contracts, 'soul_v1_api.dart'), 'utf8');
const models = fs.readFileSync(path.join(contracts, 'soul_v1_models.dart'), 'utf8');

test('Flutter manifest contains only the complete member API surface', () => {
    assert.equal(manifest.schemaVersion, 2);
    assert.equal(manifest.basePath, '/api/v1');
    assert.equal(manifest.endpointCount, 96);
    assert.equal(manifest.endpoints.length, manifest.endpointCount);
    assert.equal(new Set(manifest.endpoints.map(({ operationId }) => operationId)).size, manifest.endpointCount);
    assert.ok(manifest.endpoints.every(({ operationId }) => !operationId.includes('.admin.')));
    assert.ok(manifest.endpoints.every(({ operationId }) => !operationId.includes('.webhooks.')));
});

test('typed Flutter handoff covers the core implementation journeys', () => {
    const typed = manifest.typedHandoff;
    assert.deepEqual(typed.coveredJourneys, [
        'bootstrap', 'authentication', 'onboarding', 'photo_upload',
        'discovery', 'matches', 'chat',
    ]);
    assert.equal(typed.sessionPolicy.refreshEndpoint, null);
    assert.equal(typed.sessionPolicy.unauthorizedAction, 'clear_secure_token_and_reauthenticate');
    assert.deepEqual(typed.retryPolicy.idempotentMethods, ['GET', 'PUT', 'DELETE']);
    assert.equal(typed.retryPolicy.maximumAttempts, 3);

    const operationIds = new Set(manifest.endpoints.map(({ operationId }) => operationId));
    for (const [operationId, mapping] of Object.entries(typed.operationModels)) {
        assert.ok(operationIds.has(operationId), `${operationId} must remain a member operation`);
        for (const model of [mapping.request, mapping.response].filter(Boolean)) {
            const baseModel = model.replace(/[?<].*$/, '');
            assert.match(models, new RegExp(`class ${baseModel}(?:<[^>]+>)?\\b`));
        }
    }
});

test('representative Flutter fixtures are mapped, valid and privacy-safe', () => {
    const typed = manifest.typedHandoff;
    const operationIds = new Set(manifest.endpoints.map(({ operationId }) => operationId));
    const forbiddenKeys = /^(?:user_id|actor_user_id|target_user_id|sender_user_id|conversation_id|first_user_id|second_user_id|provider_asset_id)$/;
    assert.ok(typed.fixtures.length >= 10);

    const visit = (value) => {
        if (Array.isArray(value)) return value.forEach(visit);
        if (value === null || typeof value !== 'object') return;
        for (const [key, child] of Object.entries(value)) {
            assert.doesNotMatch(key, forbiddenKeys);
            visit(child);
        }
    };

    for (const fixture of typed.fixtures) {
        assert.ok(operationIds.has(fixture.operationId));
        const payload = JSON.parse(fs.readFileSync(path.join(contracts, 'fixtures', fixture.file), 'utf8'));
        assert.equal(payload.success, fixture.kind === 'success');
        assert.equal(typeof payload.meta.request_id, 'string');
        if (fixture.kind === 'success') {
            assert.equal(typeof payload.message, 'string');
            assert.ok(Object.hasOwn(payload, 'data'));
        } else {
            assert.equal(typeof payload.error.code, 'string');
        }
        visit(payload);
        assert.doesNotMatch(JSON.stringify(payload), /sk_live|-----BEGIN|ya29\.|eyJhbGciOi/i);
    }
});

test('typed models remain null-safe and free from admin contracts', () => {
    assert.match(models, /class SoulPatch<T>/);
    assert.match(models, /class SoulApiError/);
    assert.match(models, /class SoulCursorPage<T>/);
    assert.match(models, /abstract final class SoulTransportPolicy/);
    assert.match(models, /clear_secure_token_and_reauthenticate/);
    assert.match(models, /class SoulCloudinaryUploadResult/);
    assert.match(models, /class SoulV1Decoders/);
    assert.match(models, /'raw_nonce': rawNonce/);
    assert.match(models, /'expires_in_seconds'/);
    assert.doesNotMatch(models, /api\.v1\.admin\.|password|private_key|client_secret/i);

    const pairs = [['(', ')'], ['[', ']'], ['{', '}']];
    for (const [open, close] of pairs) {
        assert.equal([...models].filter((char) => char === open).length, [...models].filter((char) => char === close).length);
    }
});

test('Apple sign-in example carries the original nonce required by Laravel', () => {
    const operation = openapi.paths['/auth/apple'].post;
    const example = operation.requestBody.content['application/json'].example;
    assert.equal(example.raw_nonce, '<original-apple-sign-in-nonce>');
});

test('profile example uses public language codes instead of database identifiers', () => {
    const operation = openapi.paths['/onboarding/profile'].put;
    const example = operation.requestBody.content['application/json'].example;
    assert.deepEqual(example.spoken_language_codes, ['ur']);
    assert.equal(example.spoken_language_ids, undefined);
});

test('Flutter endpoints match their OpenAPI operation method and path', () => {
    const openapiOperations = new Map();
    for (const [uri, methods] of Object.entries(openapi.paths)) {
        for (const [method, operation] of Object.entries(methods)) {
            openapiOperations.set(operation.operationId, { method: method.toUpperCase(), uri });
        }
    }

    for (const endpoint of manifest.endpoints) {
        assert.deepEqual(openapiOperations.get(endpoint.operationId), { method: endpoint.method, uri: endpoint.path });
        assert.deepEqual(endpoint.pathParameters, [...endpoint.path.matchAll(/\{([^}]+)\}/g)].map((match) => match[1]));
    }
});

test('admin operations advertise browser session and CSRF authentication instead of bearer tokens', () => {
    const adminOperations = [];

    for (const methods of Object.values(openapi.paths)) {
        for (const [method, operation] of Object.entries(methods)) {
            if (operation.operationId.startsWith('api.v1.admin.')) {
                adminOperations.push({ method, operation });
            }
        }
    }

    assert.ok(adminOperations.length > 0);
    assert.equal(openapi.components.securitySchemes.adminSession.name, 'soul-session');

    for (const { method, operation } of adminOperations) {
        assert.deepEqual(operation.security, [{
            adminSession: [],
            ...(method === 'get' ? {} : { csrfToken: [] }),
        }]);
        assert.doesNotMatch(JSON.stringify(operation.security), /bearerAuth/);
    }
});

test('generated Dart catalog is safe to copy into Flutter', () => {
    assert.match(dart, /GENERATED FILE\. DO NOT EDIT\./);
    assert.match(dart, /Uri\.encodeComponent/);
    assert.doesNotMatch(dart, /api\.v1\.admin\./);
    assert.doesNotMatch(dart, /api\.v1\.webhooks\./);
    for (const endpoint of manifest.endpoints) {
        assert.match(dart, new RegExp(endpoint.operationId.replaceAll('.', '\\.')));
    }
});

test('manifest carries stable enums and transport keys without secrets', () => {
    assert.deepEqual(manifest.stableEnums.Gender, ['man', 'woman']);
    assert.deepEqual(manifest.stableEnums['Profile decision'], ['like', 'pass']);
    assert.deepEqual(manifest.transport.errorEnvelope, ['success', 'error', 'meta']);
    for (const values of Object.values(manifest.stableEnums)) {
        for (const value of values) assert.match(dart, new RegExp(`'${value}'`));
    }
    assert.doesNotMatch(JSON.stringify(manifest), /password|secret|provider-token|<token>/i);
});
