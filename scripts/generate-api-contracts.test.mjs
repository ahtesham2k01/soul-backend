import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const root = path.resolve(import.meta.dirname, '..');
const contracts = path.join(root, 'docs/contracts');
const manifest = JSON.parse(fs.readFileSync(path.join(contracts, 'flutter-v1.json'), 'utf8'));
const openapi = JSON.parse(fs.readFileSync(path.join(contracts, 'openapi-v1.json'), 'utf8'));
const dart = fs.readFileSync(path.join(contracts, 'soul_v1_api.dart'), 'utf8');

test('Flutter manifest contains only the complete member API surface', () => {
    assert.equal(manifest.schemaVersion, 1);
    assert.equal(manifest.basePath, '/api/v1');
    assert.equal(manifest.endpointCount, 91);
    assert.equal(manifest.endpoints.length, manifest.endpointCount);
    assert.equal(new Set(manifest.endpoints.map(({ operationId }) => operationId)).size, manifest.endpointCount);
    assert.ok(manifest.endpoints.every(({ operationId }) => !operationId.includes('.admin.')));
    assert.ok(manifest.endpoints.every(({ operationId }) => !operationId.includes('.webhooks.')));
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
