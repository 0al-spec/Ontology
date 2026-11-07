import { expect, test } from '@playwright/test';

test('identifies an unloaded transitive package without claiming its declaration was loaded', async ({ page }) => {
  const digest = `sha256:${'a'.repeat(64)}`;
  const source = { id: 'example.root', version: '1.0.0', sourceDigest: digest, sourceByteDigest: digest };
  const projection = {
    schemaVersion: 'ontology.diagram-projection/v1', view: 'full',
    id: source.id, version: source.version, namespace: 'root', sourceDigest: digest, sourceByteDigest: digest,
    sources: [{ ...source, namespace: 'root', alias: 'root' }],
    imports: [],
    externalImports: [{ id: 'example.core', version: '1.2.0', alias: 'pkg-core-123456789abc' }],
    classes: [{ id: 'Proposal', fqid: 'root:Proposal', extends: 'pkg-core-123456789abc:Intent',
      source: { ...source, pointer: '/spec/classes/Proposal' } }],
    relations: [], protocols: [], policies: [], stateMachines: [],
  };

  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles({
    name: 'transitive.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(projection)),
  });
  await page.getByLabel('Search graph').fill('Intent');
  await page.getByRole('button', { name: /pkg-core-123456789abc:Intent/ }).click();
  const inspector = page.getByLabel('Inspector');
  await expect(inspector).toContainText('unloaded reference');
  await expect(inspector).toContainText('example.core@1.2.0');
  await expect(inspector).toContainText('Its declaration has not been loaded');
});
