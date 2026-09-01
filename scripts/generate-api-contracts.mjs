import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const handoff = fs.readFileSync(path.join(root, 'docs/FLUTTER_API_HANDOFF.md'), 'utf8');
const endpointPattern = /^\| (GET|POST|PUT|DELETE|PATCH) \| `([^`]+)` \| `([^`]+)` \| ([^|]+) \|$/gm;
const endpoints = [...handoff.matchAll(endpointPattern)].map((match) => ({
    method: match[1],
    path: match[2],
    operationId: match[3],
    summary: match[4].trim(),
}));

if (endpoints.length !== 73) {
    throw new Error(`Expected 73 documented endpoints, found ${endpoints.length}.`);
}

const publicOperations = new Set([
    'api.v1.health',
    'api.v1.health.ready',
    'api.v1.bootstrap',
    'api.v1.auth.register.request-otp',
    'api.v1.auth.register.verify-otp',
    'api.v1.auth.login.request-otp',
    'api.v1.auth.login.verify-otp',
    'api.v1.auth.google',
    'api.v1.auth.apple',
    'api.v1.location.resolve',
    'api.v1.onboarding.religion-options',
    'api.v1.webhooks.cloudinary.moderation',
]);

const requestExamples = {
    'api.v1.auth.register.request-otp': { email: 'person@example.com' },
    'api.v1.auth.register.verify-otp': { verification_id: '01H...', code: '123456' },
    'api.v1.auth.login.request-otp': { email: 'person@example.com' },
    'api.v1.auth.login.verify-otp': { verification_id: '01H...', code: '123456' },
    'api.v1.auth.google': { id_token: '<google-id-token>', device_name: 'Pixel' },
    'api.v1.auth.apple': { identity_token: '<apple-identity-token>', device_name: 'iPhone' },
    'api.v1.location.resolve': { latitude: 24.8607, longitude: 67.0011, accuracy_meters: 25 },
    'api.v1.discovery.preferences.update': { preferred_gender: 'woman', minimum_age: 24, maximum_age: 35, same_country_only: true },
    'api.v1.matching.decisions.store': { decision: 'like' },
    'api.v1.messages.store': { body: 'Salam' },
    'api.v1.safety.blocks.store': { reason: 'Harassment' },
    'api.v1.safety.reports.store': { category: 'harassment', details: 'Repeated unwanted messages' },
    'api.v1.verification.cases.store': { type: 'selfie_review' },
    'api.v1.verification.appeals.store': { statement: 'Please review this verification decision again.' },
    'api.v1.devices.store': { platform: 'android', push_token: '<provider-token>', device_name: 'Pixel' },
    'api.v1.privacy.deletion.store': { confirmation: 'DELETE MY ACCOUNT' },
    'api.v1.admin.users.status.update': { status: 'suspended', reason: 'Confirmed safety escalation' },
    'api.v1.admin.admins.store': { name: 'Safety Moderator', email: 'moderator@example.com', password: '<strong-password>', password_confirmation: '<strong-password>', role: 'moderator', reason: 'Joining safety operations' },
    'api.v1.admin.admins.role.update': { role: 'super_admin', reason: 'Promoted to operations lead' },
    'api.v1.admin.admins.destroy': { reason: 'Admin left operations' },
    'api.v1.admin.religion-taxonomy.store': { parent_id: null, type: 'religion', slug: 'islam', is_active: true, sort_order: 0, translations: [{ locale: 'en', label: 'Islam', description: null }], country_codes: [], reason: 'Approved taxonomy maintenance' },
    'api.v1.admin.religion-taxonomy.update': { parent_id: null, type: 'religion', slug: 'islam', is_active: true, sort_order: 0, translations: [{ locale: 'en', label: 'Islam', description: null }], country_codes: ['PK'], reason: 'Approved taxonomy maintenance' },
    'api.v1.admin.notification-broadcasts.store': { title: 'Safety update', body: 'Important information for SOUL members.', category: 'safety', audience_type: 'country', audience_value: 'PK', reason: 'Approved member communication' },
    'api.v1.admin.notification-broadcasts.send': { confirmation: 'SEND', reason: 'Approved member communication' },
};

const tags = (operationId) => {
    const segment = operationId.split('.')[2];
    return segment === 'matching' || segment === 'matches' || segment === 'messages'
        ? 'Interactions'
        : segment.charAt(0).toUpperCase() + segment.slice(1);
};

const paths = {};
for (const endpoint of endpoints) {
    const parameters = [...endpoint.path.matchAll(/\{([^}]+)\}/g)].map((match) => ({
        name: match[1],
        in: 'path',
        required: true,
        schema: { type: match[1] === 'position' ? 'integer' : 'string' },
    }));
    const example = requestExamples[endpoint.operationId];
    const operation = {
        operationId: endpoint.operationId,
        summary: endpoint.summary,
        tags: [tags(endpoint.operationId)],
        ...(parameters.length ? { parameters } : {}),
        ...(endpoint.operationId.startsWith('api.v1.admin.')
            ? { security: [{ adminSession: [] }] }
            : endpoint.operationId === 'api.v1.webhooks.cloudinary.moderation'
                ? { security: [{ cloudinarySignature: [] }] }
                : !publicOperations.has(endpoint.operationId)
                    ? { security: [{ bearerAuth: [] }] }
                    : {}),
        ...(example ? {
            requestBody: {
                required: true,
                content: { 'application/json': { schema: { type: 'object' }, example } },
            },
        } : {}),
        responses: {
            '2XX': { $ref: '#/components/responses/Success' },
            '401': { $ref: '#/components/responses/Error' },
            '422': { $ref: '#/components/responses/Error' },
            '429': { $ref: '#/components/responses/Error' },
        },
    };
    paths[endpoint.path] ??= {};
    paths[endpoint.path][endpoint.method.toLowerCase()] = operation;
}

const openapi = {
    openapi: '3.1.0',
    info: {
        title: 'SOUL V1 API',
        version: '1.0.0',
        description: 'Machine-readable companion to docs/FLUTTER_API_HANDOFF.md.',
    },
    servers: [{ url: 'http://localhost/api/v1', description: 'Local development; replace the origin per environment' }],
    paths,
    components: {
        securitySchemes: {
            bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'Sanctum token' },
            adminSession: { type: 'apiKey', in: 'cookie', name: 'laravel_session' },
            cloudinarySignature: { type: 'apiKey', in: 'header', name: 'X-Cld-Signature' },
        },
        schemas: {
            SuccessEnvelope: {
                type: 'object',
                required: ['success', 'message', 'data', 'meta'],
                properties: {
                    success: { const: true }, message: { type: 'string' }, data: {},
                    meta: { type: 'object', properties: { request_id: { type: 'string' } } },
                },
            },
            ErrorEnvelope: {
                type: 'object',
                required: ['success', 'error', 'meta'],
                properties: {
                    success: { const: false },
                    error: {
                        type: 'object', required: ['code', 'message', 'details'],
                        properties: { code: { type: 'string' }, message: { type: 'string' }, details: { type: 'object' } },
                    },
                    meta: { type: 'object', properties: { request_id: { type: 'string' } } },
                },
            },
        },
        responses: {
            Success: { description: 'Successful SOUL response', content: { 'application/json': { schema: { $ref: '#/components/schemas/SuccessEnvelope' } } } },
            Error: { description: 'Standard SOUL error response', content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorEnvelope' } } } },
        },
    },
};

const folders = new Map();
for (const endpoint of endpoints) {
    const folder = tags(endpoint.operationId);
    if (!folders.has(folder)) folders.set(folder, []);
    const example = requestExamples[endpoint.operationId];
    folders.get(folder).push({
        name: endpoint.summary,
        request: {
            method: endpoint.method,
            header: [{ key: 'Accept', value: 'application/json' }],
            ...(publicOperations.has(endpoint.operationId) || endpoint.operationId.startsWith('api.v1.admin.') ? { auth: { type: 'noauth' } } : {}),
            ...(example ? { body: { mode: 'raw', raw: JSON.stringify(example, null, 2), options: { raw: { language: 'json' } } } } : {}),
            url: {
                raw: `{{baseUrl}}${endpoint.path}`,
                host: ['{{baseUrl}}'],
                path: endpoint.path.split('/').filter(Boolean),
            },
            description: `${endpoint.operationId}: ${endpoint.summary}`,
        },
    });
}

const postman = {
    info: {
        name: 'SOUL V1 API',
        description: 'Generated from the versioned Flutter handoff contract.',
        schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
    },
    auth: { type: 'bearer', bearer: [{ key: 'token', value: '{{token}}', type: 'string' }] },
    variable: [
        { key: 'baseUrl', value: 'http://localhost/api/v1' },
        { key: 'token', value: '' },
    ],
    item: [...folders].map(([name, item]) => ({ name, item })),
};

const output = path.join(root, 'docs/contracts');
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(path.join(output, 'openapi-v1.json'), `${JSON.stringify(openapi, null, 2)}\n`);
fs.writeFileSync(path.join(output, 'postman-v1.collection.json'), `${JSON.stringify(postman, null, 2)}\n`);

console.log(`Generated OpenAPI and Postman contracts for ${endpoints.length} endpoints.`);
