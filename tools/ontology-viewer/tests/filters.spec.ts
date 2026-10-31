import { expect, test } from '@playwright/test';

const fixture = process.env.ONTOLOGY_GRAPH_FIXTURE;

test('hides and dims categories without moving a dragged node or the viewport', async ({ page }) => {
  if (!fixture) throw new Error('Set ONTOLOGY_GRAPH_FIXTURE to a generated ontology.graph.json');
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles(fixture);
  await page.getByLabel('Search graph').fill('MotivationHypothesis');
  await page.getByRole('button', { name: /motivcore:MotivationHypothesis/i }).click();
  await expect(page.getByLabel('Inspector')).toContainText('/spec/classes/MotivationHypothesis');
  const node = page.locator('[data-id="classes/motivcore:MotivationHypothesis"]');
  const zoom = async () => page.locator('.react-flow__viewport').evaluate((element) =>
    Math.round(new DOMMatrixReadOnly(getComputedStyle(element).transform).a * 100));
  await expect.poll(zoom).toBe(100);
  const bounds = await node.boundingBox();
  if (!bounds) throw new Error('The node has no bounds');
  await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
  await page.mouse.down();
  await page.mouse.move(bounds.x + bounds.width / 2 + 30, bounds.y + bounds.height / 2 + 18, { steps: 5 });
  await page.mouse.up();
  await page.locator('.filter-panel summary').click();
  const transform = await node.evaluate((element) => getComputedStyle(element).transform);
  const viewport = await page.locator('.react-flow__viewport').evaluate((element) => getComputedStyle(element).transform);
  const classes = page.getByRole('checkbox', { name: 'Classes', exact: true });
  await classes.uncheck();
  await expect(node).toHaveCount(0);
  await expect(page.getByRole('button', { name: /motivcore:MotivationHypothesis/i })).toHaveCount(0);
  await expect(page.getByLabel('Inspector').getByRole('status')).toContainText('outside the active filters');
  await expect(page.locator('.react-flow__edge')).toHaveCount(0);
  await expect.poll(() => page.locator('.react-flow__viewport').evaluate((element) => getComputedStyle(element).transform)).toBe(viewport);

  await classes.check();
  await expect(node).toBeVisible();
  await expect.poll(() => node.evaluate((element) => getComputedStyle(element).transform)).toBe(transform);
  await expect(page.getByRole('button', { name: /motivcore:MotivationHypothesis/i })).toBeVisible();
  await expect(page.getByLabel('Inspector').getByRole('status')).toHaveCount(0);
  await page.getByRole('radio', { name: 'Dim' }).check();
  await classes.uncheck();
  await expect(node).toHaveClass(/filter-dim/);
  await expect(node).toHaveCSS('opacity', '0.15');
  await expect(page.locator('.react-flow__edge').first()).toHaveClass(/filter-dim/);
  await expect.poll(() => page.locator('.react-flow__minimap-node.filter-dim').count()).toBeGreaterThan(0);
  await expect.poll(() => node.evaluate((element) => getComputedStyle(element).transform)).toBe(transform);

  await classes.check();
  await page.getByRole('radio', { name: 'Hide' }).check();
  await page.getByRole('checkbox', { name: 'Ontology relations' }).uncheck();
  await expect(node).toBeVisible();
  await expect(page.locator('.react-flow__edge')).toHaveCount(0);
  await page.getByRole('button', { name: 'Reset filters' }).click();
  await expect.poll(() => page.locator('.react-flow__edge').count()).toBeGreaterThan(0);
  await expect.poll(() => node.evaluate((element) => getComputedStyle(element).transform)).toBe(transform);
  await expect.poll(() => page.locator('.react-flow__viewport').evaluate((element) => getComputedStyle(element).transform)).toBe(viewport);
});

test('filters imported and unresolved nodes independently on a narrow screen', async ({ page }) => {
  if (!fixture) throw new Error('Set ONTOLOGY_GRAPH_FIXTURE to a generated ontology.graph.json');
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles(fixture);
  await expect(page.locator('.sidebar-footer')).toBeVisible();
  const local = page.locator('[data-id="classes/motivcore:MotivationHypothesis"]');
  const imported = page.locator('[data-id="classes/eventcore:Interpretation"]');
  const unresolved = page.locator('[data-id="external/classes/eventcore:Fact"]');
  const relation = page.locator('[data-id="relation/motivcore:hypothesisView/0"]');
  await expect(local).toBeVisible();
  await expect(imported).toBeVisible();
  await expect(unresolved).toBeVisible();
  await page.locator('.filter-panel summary').click();
  await page.getByRole('checkbox', { name: 'Imported', exact: true }).uncheck();
  await expect(imported).toHaveCount(0);
  await expect(local).toBeVisible();
  await expect(unresolved).toBeVisible();
  await expect(relation).toHaveCount(0);
  await page.getByRole('checkbox', { name: 'Unresolved', exact: true }).uncheck();
  await expect(unresolved).toHaveCount(0);
  await page.getByRole('checkbox', { name: 'Imported', exact: true }).check();
  await expect(imported).toBeVisible();
  await expect(relation).toHaveCount(1);
  await expect(unresolved).toHaveCount(0);
  await expect(page.getByRole('radio', { name: 'Hide' })).toBeInViewport();
  await expect(page.locator('.filter-panel summary')).toBeInViewport();
  await page.screenshot({ path: test.info().outputPath('filters-mobile.png'), fullPage: true });
});
