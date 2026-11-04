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
  const relation = page.locator('[data-id="relations/membership:addsRepositoryTo"]');
  const action = page.locator('[data-id="classes/membership:AddRepository"]');
  await expect(relation).toContainText('subject: User');
  await expect(relation).toContainText('action: AddRepository');
  await expect(relation).toContainText('object: Project');
  await expect(action).toContainText('Action');
  await expect(action).toContainText('repository: Ref<Repository>');
  await expect(page.locator('[data-testid="rf__edge-role/membership:addsRepositoryTo/action"]')).toHaveCount(1);
  await expect(page.locator('[data-testid="rf__edge-field/membership:AddRepository/repository"]')).toHaveCount(1);
  await expect(page.locator('[data-testid="rf__edge-relation/membership:addsRepositoryTo/0"]')).toHaveCount(0);
  await page.getByRole('button', { name: 'Fit View' }).click();
  // The preceding search focus animates for 300 ms; let it finish before measuring the SVG path.
  await page.waitForTimeout(400);
  const point = await page.locator('[data-testid="rf__edge-field/membership:AddRepository/repository"] .react-flow__edge-path')
    .evaluate((element) => {
      const path = element as SVGPathElement;
      const location = path.getPointAtLength(path.getTotalLength() * 0.5);
      const matrix = path.getScreenCTM();
      if (!matrix) throw new Error('Field wire is not visible');
      const screen = new DOMPoint(location.x, location.y).matrixTransform(matrix);
      return { x: screen.x, y: screen.y };
    });
  await page.mouse.click(point.x, point.y);
  await expect(inspector).toContainText('Field');
  await expect(inspector).toContainText('membership:Repository');
  await expect(inspector).toContainText('/spec/classes/AddRepository/fields/repository');
  await relation.click();
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

test('catalog lists declarations without search and selects their canonical nodes', async ({ page }) => {
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles({
    name: 'membership.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(fixture)),
  });
  const catalog = page.getByLabel('Declaration catalog');
  for (const name of ['membership:AddRepository', 'membership:User', 'membership:Project', 'membership:Repository', 'membership:addsRepositoryTo']) {
    await expect(catalog.getByRole('button', { name: new RegExp(name) })).toHaveCount(1);
  }
  await catalog.getByRole('button', { name: 'membership:AddRepository action' }).click();
  await expect(page.getByLabel('Inspector').getByRole('heading', { name: 'membership:AddRepository' })).toBeVisible();
  await expect(page.getByLabel('Inspector')).toContainText('Action');
  await page.locator('.filter-panel summary').click();
  await page.getByRole('checkbox', { name: 'Classes', exact: true }).uncheck();
  await page.locator('.filter-panel summary').click();
  await expect(catalog.getByRole('button', { name: 'membership:Repository class · hidden by filters' })).toBeVisible();
  await catalog.getByRole('button', { name: 'membership:Repository class · hidden by filters' }).click();
  await expect(page.getByLabel('Inspector').getByRole('status')).toContainText('outside the active filters');
  await page.locator('.filter-panel summary').click();
  await expect(page.getByRole('checkbox', { name: 'Classes', exact: true })).not.toBeChecked();
  await page.locator('.filter-panel summary').click();
  await page.getByLabel('Search graph').fill('Repository');
  await expect(page.getByLabel('Search results').getByRole('button', { name: /membership:Repository/ })).toHaveCount(0);
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
