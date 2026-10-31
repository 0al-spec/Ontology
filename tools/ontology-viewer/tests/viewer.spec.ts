import { expect, test } from '@playwright/test';

const fixture = process.env.ONTOLOGY_GRAPH_FIXTURE;

test('opens a real package projection, searches, inspects and retains the graph after invalid input', async ({ page }) => {
  if (!fixture) throw new Error('Set ONTOLOGY_GRAPH_FIXTURE to a generated motivation-relations ontology.graph.json');
  await page.goto('/');
  await expect(page.getByRole('heading', { name: /make your ontology/i })).toBeVisible();
  await page.getByLabel('Open graph JSON').setInputFiles(fixture);
  await expect(page.getByRole('heading', { name: 'org.0al.motivation.core' })).toBeVisible();
  await expect.poll(() => page.locator('.react-flow__node').count()).toBeGreaterThan(10);
  await page.getByLabel('Search graph').fill('MotivationHypothesis');
  await page.getByRole('button', { name: /motivcore:MotivationHypothesis/i }).click();
  await expect(page.getByLabel('Inspector')).toContainText('/spec/classes/MotivationHypothesis');
  await expect(page.getByLabel('Inspector')).toContainText('org.0al.motivation.core');
  const zoom = async () => page.locator('.react-flow__viewport').evaluate((element) =>
    Math.round(new DOMMatrixReadOnly(getComputedStyle(element).transform).a * 100));
  await expect.poll(zoom).toBe(100);
  await page.locator('.react-flow__controls-zoomout').click();
  await expect.poll(zoom).toBeLessThan(100);
  await page.getByRole('button', { name: /motivcore:MotivationHypothesis/i }).click();
  await expect.poll(zoom).toBe(100);
  const node = page.locator('[data-id="classes/motivcore:MotivationHypothesis"]');
  await expect(node).toBeVisible();
  const before = await node.getAttribute('style');
  const bounds = await node.boundingBox();
  if (!bounds) throw new Error('The selected graph node has no bounds');
  await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
  await page.mouse.down();
  await page.mouse.move(bounds.x + bounds.width / 2 + 28, bounds.y + bounds.height / 2 + 20, { steps: 5 });
  await page.mouse.up();
  await expect(node).not.toHaveAttribute('style', before || '');
  await page.getByLabel('Search graph').fill('SourceAssertion');
  await page.getByRole('button', { name: /eventcore:SourceAssertion/i }).click();
  await expect(page.getByLabel('Inspector')).toContainText('unloaded reference');
  await page.getByLabel('Search graph').fill('eventcore:Interpretation');
  await page.locator('.search-results button').filter({ has: page.getByText('eventcore:Interpretation', { exact: true }) }).click();
  await expect(page.getByLabel('Inspector')).toContainText('org.0al.events.core');
  await expect(page.getByLabel('Inspector')).toContainText('/spec/classes/Interpretation');
  await page.getByLabel('Search graph').fill('hypothesisView');
  await page.getByRole('button', { name: /motivcore:hypothesisView/i }).click();
  await expect(page.getByLabel('Inspector')).toContainText('eventcore:InterpretationCandidate');
  await page.getByLabel('Open graph JSON').setInputFiles({ name: 'invalid.json', mimeType: 'application/json', buffer: Buffer.from('{"schemaVersion":"unknown"}') });
  await expect(page.getByRole('alert')).toContainText('Unsupported schemaVersion');
  await expect(page.getByRole('heading', { name: 'org.0al.motivation.core' })).toBeVisible();
  await page.screenshot({ path: test.info().outputPath('desktop.png'), fullPage: true });
});

test('narrow view keeps the graph, search and inspector accessible', async ({ page }) => {
  if (!fixture) throw new Error('Set ONTOLOGY_GRAPH_FIXTURE to a generated motivation-relations ontology.graph.json');
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles(fixture);
  await expect(page.getByLabel('Search graph')).toBeVisible();
  await page.getByLabel('Search graph').fill('MotivationHypothesis');
  await page.getByRole('button', { name: /motivcore:MotivationHypothesis/i }).click();
  await expect(page.getByLabel('Inspector')).toContainText('/spec/classes/MotivationHypothesis');
  await expect(page.getByLabel('Ontology graph')).toBeVisible();
  await page.screenshot({ path: test.info().outputPath('mobile.png'), fullPage: true });
});
