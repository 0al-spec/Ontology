import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { expect, test, type Page } from '@playwright/test';
import { parseProjection, type Declaration, type Projection } from '../src/projection';

let fixture: Projection & { sourceDigest: string; sourceByteDigest: string };
test.beforeAll(() => {
  const viz = process.env.ONTOLOGY_VIZ;
  if (!viz) throw new Error('Set ONTOLOGY_VIZ to the matching ontologyviz executable');
  const source = path.resolve('../../Examples/repository-membership/package.yaml');
  const directory = mkdtempSync(path.join(process.env.ONTOLOGY_VIEWER_TEST_TMP || os.tmpdir(), 'ontology-action-reference-'));
  try {
    execFileSync(viz, [source, '--format', 'json', '--out', directory]);
    const parsed = parseProjection(JSON.parse(readFileSync(path.join(directory, 'ontology.graph.json'), 'utf8')) as unknown);
    const { sourceDigest, sourceByteDigest } = parsed.sources[0];
    if (typeof sourceDigest !== 'string' || typeof sourceByteDigest !== 'string') throw new Error('Projection root digests are missing');
    fixture = { ...parsed, sourceDigest, sourceByteDigest };
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

async function openGraph(page: Page, graph: unknown) {
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles({
    name: 'membership.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(graph)),
  });
  await page.getByLabel('Search graph').fill('addsRepositoryTo');
  await page.getByRole('button', { name: 'membership:addsRepositoryTo relation' }).click();
}

test('navigates from relation to action to reference target without opening raw data', async ({ page }) => {
  await openGraph(page, fixture);
  const inspector = page.getByLabel('Inspector');
  await expect(inspector.locator('dl')).toContainText('Subject');
  await expect(inspector.locator('dl')).toContainText('membership:User');
  await expect(inspector.locator('dl')).toContainText('Object');
  await expect(inspector.locator('dl')).toContainText('membership:Project');
  await inspector.getByRole('button', { name: 'membership:AddRepository' }).click();
  await expect(inspector.getByRole('heading', { name: 'membership:AddRepository' })).toBeVisible();
  await expect(inspector.locator('dl')).toContainText('repository: Ref<Repository>');
  await inspector.getByRole('button', { name: 'repository: Ref<Repository>', exact: true }).click();
  await expect(inspector.getByRole('heading', { name: 'membership:Repository' })).toBeVisible();
  await expect(inspector.locator('details')).not.toHaveAttribute('open', '');
});

test('presents oneOf objects and leaves unloaded references as text', async ({ page }) => {
  const graph = structuredClone(fixture);
  graph.relations[0].range = { oneOf: ['membership:Project', 'membership:Repository'] };
  graph.classes = graph.classes.filter((item: { fqid: string }) => item.fqid !== 'membership:Repository');
  await openGraph(page, graph);
  const inspector = page.getByLabel('Inspector');
  await expect(inspector.locator('dl')).toContainText('Object (oneOf)');
  await expect(inspector.locator('dl')).toContainText('membership:Project | membership:Repository');
  await inspector.getByRole('button', { name: 'membership:AddRepository' }).click();
  await expect(inspector.locator('dl')).toContainText('repository: Ref<Repository>');
  await expect(inspector.getByRole('button', { name: 'repository: Ref<Repository>', exact: true })).toHaveCount(0);
});

test('shows independently named ref fields on a class derived from a local action', async ({ page }) => {
  const graph = structuredClone(fixture);
  const action = graph.classes.find((item: { fqid: string }) => item.fqid === 'membership:AddRepository');
  if (!action || !Array.isArray(action.fields)) throw new Error('Example action fields are missing');
  const field: unknown = action.fields[0];
  if (typeof field !== 'object' || field === null || Array.isArray(field)) throw new Error('Example ref field is missing');
  const base: Declaration = { ...action, id: 'AddRepositoryBase', fqid: 'membership:AddRepositoryBase',
    source: { ...action.source, pointer: '/spec/classes/AddRepositoryBase' } };
  delete base.fields;
  graph.classes.push(base);
  action.kind = 'AddRepositoryBase';
  action.extends = 'membership:AddRepositoryBase';
  action.fields.push({ ...field, id: 'secondaryRepository' });
  await openGraph(page, graph);
  const inspector = page.getByLabel('Inspector');
  await inspector.getByRole('button', { name: 'membership:AddRepository' }).click();
  await expect(inspector.getByRole('button', { name: 'repository: Ref<Repository>', exact: true })).toBeVisible();
  await inspector.getByRole('button', { name: 'secondaryRepository: Ref<Repository>', exact: true }).click();
  await expect(inspector.getByRole('heading', { name: 'membership:Repository' })).toBeVisible();
});

test('keeps binary relation Domain and Range when there is no action', async ({ page }) => {
  const graph = structuredClone(fixture);
  delete graph.relations[0].action;
  await openGraph(page, graph);
  const inspector = page.getByLabel('Inspector');
  await expect(inspector.locator('dl')).toContainText('Domain');
  await expect(inspector.locator('dl')).toContainText('Range');
  await expect(inspector.locator('dl')).not.toContainText('Subject');
});
