import fs from 'node:fs';
import path from 'node:path';

const root = process.env.SOUL_MIGRATION_ROOT ?? process.cwd();
const migrationDirectory = path.join(root, 'database/migrations');
const maximumIdentifierLength = 64;
const failures = [];

const generatedName = (table, columns, suffix) => `${table}_${columns.join('_')}_${suffix}`;
const auditBlock = (filename, table, block) => {
    for (const match of block.matchAll(/\$table->(index|unique)\(\[([^\]]+)]\s*\)/g)) {
        const columns = [...match[2].matchAll(/'([^']+)'/g)].map((column) => column[1]);
        const identifier = generatedName(table, columns, match[1]);

        if (identifier.length > maximumIdentifierLength) {
            failures.push({ filename, identifier, length: identifier.length });
        }
    }

    for (const match of block.matchAll(/\$table->foreignId\('([^']+)'\)([\s\S]{0,240}?)constrained\(/g)) {
        const identifier = generatedName(table, [match[1]], 'foreign');
        if (identifier.length > maximumIdentifierLength) {
            failures.push({ filename, identifier, length: identifier.length });
        }
    }
};

const filenames = fs.readdirSync(migrationDirectory).filter((name) => name.endsWith('.php')).sort();
for (const filename of filenames) {
    const source = fs.readFileSync(path.join(migrationDirectory, filename), 'utf8');

    for (const match of source.matchAll(/Schema::(?:create|table)\('([^']+)'[\s\S]*?\n\s*}\);/g)) {
        auditBlock(filename, match[1], match[0]);
    }

    for (const match of source.matchAll(/Schema::(?:create|table)\('([^']+)',\s*fn\s*\([^)]*\)\s*=>\s*([^;]+)\);/g)) {
        auditBlock(filename, match[1], match[2]);
    }
}

const report = {
    maximumIdentifierLength,
    migrations: filenames.length,
    failures,
};

process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
process.exitCode = failures.length === 0 ? 0 : 1;
