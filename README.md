# SOUL Backend

Laravel API and custom React administration panel for the SOUL Android/iOS member application.

## Documentation

All human-readable product and engineering documentation lives in one professionally ordered source:

- [SOUL V1 complete documentation](docs/SOUL_V1_MASTER_DOCUMENTATION.md)

Machine-readable API contracts remain separate for tooling:

- [OpenAPI 3.1](docs/contracts/openapi-v1.json)
- [Postman collection](docs/contracts/postman-v1.collection.json)

## Local setup

```bash
composer install
npm ci
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan test
npm run build
```

Do not use development defaults in production. Follow the production-readiness and release-closure chapters in the master documentation.
