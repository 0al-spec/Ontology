import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { expect, test, type Page } from '@playwright/test';
import { parseProjection, type Declaration, type Projection } from '../src/projection';

type GraphFixture = Projection & { sourceDigest: string; sourceByteDigest: string };
let fixture: GraphFixture;

function exportGraph(source: string, view: Projection['view'] = 'full'): GraphFixture {
  const viz = process.env.ONTOLOGY_VIZ;
  if (!viz) throw new Error('Set ONTOLOGY_VIZ to the matching ontologyviz executable');
  const directory = mkdtempSync(path.join(process.env.ONTOLOGY_VIEWER_TEST_TMP || os.tmpdir(), 'ontology-action-reference-'));
  try {
    execFileSync(viz, [path.resolve(source), '--view', view, '--format', 'json', '--out', directory]);
    const parsed = parseProjection(JSON.parse(readFileSync(path.join(directory, 'ontology.graph.json'), 'utf8')) as unknown);
    const { sourceDigest, sourceByteDigest } = parsed.sources[0];
    if (typeof sourceDigest !== 'string' || typeof sourceByteDigest !== 'string') throw new Error('Projection root digests are missing');
    return { ...parsed, sourceDigest, sourceByteDigest };
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

test.beforeAll(() => { fixture = exportGraph('../../Examples/repository-membership/package.yaml'); });

async function openGraph(page: Page, graph: unknown, relation = 'membership:addsRepositoryTo', name = 'membership.json') {
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles({
    name, mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(graph)),
  });
  await page.getByLabel('Search graph').fill(relation);
  await page.getByRole('button', { name: `${relation} relation`, exact: true }).click();
}

test('lays out membership inputs in port order without crossing wires', async ({ page }) => {
  await openGraph(page, fixture);
  await page.locator('.filter-panel summary').click();
  await page.getByRole('checkbox', { name: 'Unresolved', exact: true }).uncheck();
  const wires = page.locator('.react-flow__edge:visible .react-flow__edge-path');
  await expect(wires).toHaveCount(4);

  const crossings = await wires.evaluateAll(elements => {
    const paths = elements.filter((element): element is SVGPathElement => element instanceof SVGPathElement);
    const intersecting: string[][] = [];
    for (const [index, a] of paths.entries()) {
      for (const b of paths.slice(index + 1)) {
        const transform = b.getScreenCTM()!.inverse().multiply(a.getScreenCTM()!);
        const length = a.getTotalLength();
        for (let distance = 0; distance <= length; distance += 0.5) {
          if (b.isPointInStroke(a.getPointAtLength(distance).matrixTransform(transform))) {
            intersecting.push([a, b].map(path => path.closest('.react-flow__edge')!.getAttribute('data-id')!));
            break;
          }
        }
      }
    }
    return intersecting;
  });
  expect(crossings).toEqual([]);

  const rows = await Promise.all(['User', 'AddRepository', 'Project'].map(name =>
    page.locator(`[data-id="classes/membership:${name}"]`).evaluate(node => node.getBoundingClientRect().top)));
  expect(rows[0]).toBeLessThan(rows[1]);
  expect(rows[1]).toBeLessThan(rows[2]);
});

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

test('rejects a field attributed to another class and retains the open graph', async ({ page }) => {
  await openGraph(page, fixture);
  const modified = structuredClone(fixture);
  const field = modified.classes.find(item => item.id === 'AddRepository')?.fields?.find(item => item.id === 'repository');
  if (!field?.source) throw new Error('The exported repository field has no source');
  field.source.pointer = '/spec/classes/Project/fields/repository';
  await page.getByLabel('Open graph JSON').setInputFiles({
    name: 'retargeted.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(modified)),
  });
  await expect(page.getByRole('alert')).toContainText('membership:AddRepository.fields.repository.source.pointer');
  await expect(page.getByLabel('Inspector').getByRole('heading', { name: 'membership:addsRepositoryTo' })).toBeVisible();
  await expect(page.locator('.topbar')).toContainText('membership.json');
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
  const field = action.fields[0];
  if (!field?.source) throw new Error('Example ref field source is missing');
  const base: Declaration = { ...action, id: 'AddRepositoryBase', fqid: 'membership:AddRepositoryBase',
    source: { ...action.source, pointer: '/spec/classes/AddRepositoryBase' } };
  delete base.fields;
  graph.classes.push(base);
  action.kind = 'AddRepositoryBase';
  action.extends = 'membership:AddRepositoryBase';
  action.fields.push({ ...field, id: 'secondaryRepository',
    source: { ...field.source, pointer: '/spec/classes/AddRepository/fields/secondaryRepository' } });
  await openGraph(page, graph);
  const inspector = page.getByLabel('Inspector');
  await inspector.getByRole('button', { name: 'membership:AddRepository' }).click();
  await expect(inspector.getByRole('button', { name: 'repository: Ref<Repository>', exact: true })).toBeVisible();
  await inspector.getByRole('button', { name: 'secondaryRepository: Ref<Repository>', exact: true }).click();
  await expect(inspector.getByRole('heading', { name: 'membership:Repository' })).toBeVisible();
});

const examcalcPackage = '../../SPECS/ontology/packages/examcalc/domain-ontology-package.yaml';

test('shows Subject and Object for examcalc relationships without inventing an action', async ({ page }) => {
  await openGraph(page, exportGraph(examcalcPackage, 'relations'), 'examcalc:requires_policy', 'examcalc.json');
  const inspector = page.getByLabel('Inspector');
  await expect(inspector.locator('dt')).toHaveText(['Subject', 'Object']);
  await expect(inspector.locator('dd')).toHaveText(['examcalc:Exam', 'examcalc:ExamPolicyProfile']);
  await page.getByLabel('Search graph').fill('examcalc:records');
  await page.getByRole('button', { name: 'examcalc:records relation' }).click();
  await expect(inspector.locator('dt')).toHaveText(['Subject', 'Object (oneOf)']);
  await expect(inspector.locator('dd')).toHaveText(['examcalc:AuditLogEntry', 'examcalc:ExamModeSession | examcalc:PolicyViolation']);
});

test('separates and selects parallel examcalc links in both line styles', async ({ page }) => {
  await openGraph(page, exportGraph(examcalcPackage, 'relations'), 'examcalc:requires_policy', 'examcalc.json');
  await expect(page.getByRole('radio', { name: 'Rect', exact: true })).toBeChecked();
  // The catalog animates the viewport when locating the selected relation.
  await page.waitForTimeout(350);
  await page.getByRole('button', { name: 'Fit View' }).click();
  const viewport = page.locator('.react-flow__viewport');
  await expect.poll(() => page.locator('.react-flow__node').evaluateAll(nodes => {
    const canvas = document.querySelector('.canvas')!.getBoundingClientRect();
    return nodes.every(node => {
      const bounds = node.getBoundingClientRect();
      return bounds.left >= canvas.left && bounds.right <= canvas.right;
    });
  })).toBe(true);
  const node = page.locator('[data-id="classes/examcalc:ExamPolicyProfile"]');
  const position = await node.getAttribute('style');
  const transform = await viewport.getAttribute('style');
  const edge = (id: string) => page.getByTestId(`rf__edge-relation/examcalc:${id}/0`);
  const wire = (id: string) => edge(id).locator('.react-flow__edge-path');
  const initial = await wire('allows').getAttribute('d');
  for (const style of ['Rect', 'Curve']) {
    await page.getByRole('radio', { name: style, exact: true }).check();
    await expect(page.getByLabel('Inspector').getByRole('heading')).toHaveText(style === 'Rect' ? 'examcalc:requires_policy' : 'examcalc:denies');
    await expect(node).toHaveAttribute('style', position!);
    await expect(viewport).toHaveAttribute('style', transform!);
    const allowsPath = await wire('allows').getAttribute('d');
    expect(allowsPath).not.toEqual(await wire('denies').getAttribute('d'));
    expect(allowsPath).toMatch(style === 'Rect' ? /H/ : /C/);
    const singlePath = await wire('requires_policy').getAttribute('d');
    expect(singlePath?.includes('C')).toBe(style === 'Curve');
    const allows = edge('allows').locator('.react-flow__edge-text');
    const denies = edge('denies').locator('.react-flow__edge-text');
    const boxes = await Promise.all([allows.boundingBox(), denies.boundingBox()]);
    expect(boxes[0]!.y + boxes[0]!.height).toBeLessThan(boxes[1]!.y);
    for (const [id, label] of [['allows', allows], ['denies', denies]] as const) {
      const box = (await label.boundingBox())!;
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await expect(page.getByLabel('Inspector').getByRole('heading')).toHaveText(`examcalc:${id}`);
    }
  }
  await page.getByRole('radio', { name: 'Rect', exact: true }).check();
  await expect(wire('allows')).toHaveAttribute('d', initial!);
});
