import { expect, test } from '@playwright/test';

test('shows qualified node names with a separate namespace badge without changing their identities', async ({ page }) => {
  const digest = `sha256:${'a'.repeat(64)}`;
  const source = { id: 'example.promotion', version: '1.0.0', sourceDigest: digest, sourceByteDigest: digest };
  const external = 'exceptionally-long-external-namespace-for-visual-check';
  const graph = {
    schemaVersion: 'ontology.diagram-projection/v1', view: 'full',
    id: source.id, version: source.version, namespace: 'sgpromotion', sourceDigest: digest, sourceByteDigest: digest,
    sources: [{ ...source, namespace: 'sgpromotion', alias: 'sgpromotion' }],
    imports: [{ id: 'ontology.foundation', namespace: 'ont', version: '0.2.0' },
      { id: 'example.external', namespace: external, version: '1.0.0' }],
    classes: [
      { id: 'MaterializeSpecDraft', fqid: 'sgpromotion:MaterializeSpecDraft', extends: 'ont:Action',
        fields: [{ id: 'target', type: 'ref', target: 'sgpromotion:Target' }],
        source: { ...source, pointer: '/spec/classes/MaterializeSpecDraft' } },
      { id: 'Target', fqid: 'sgpromotion:Target', extends: `${external}:Base`,
        source: { ...source, pointer: '/spec/classes/Target' } },
    ],
    relations: [{ id: 'targets', fqid: 'sgpromotion:targets', domain: 'sgpromotion:Target',
      range: 'sgpromotion:Target', action: 'sgpromotion:MaterializeSpecDraft',
      source: { ...source, pointer: '/spec/relations/targets' } }], protocols: [], policies: [],
    stateMachines: [{ id: 'Review', fqid: 'sgpromotion:Review', states: ['draft'], transitions: [],
      source: { ...source, pointer: '/spec/stateMachines/Review' } }],
  };
  await page.goto('/');
  await page.getByLabel('Open graph JSON').setInputFiles({
    name: 'namespace.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(graph)),
  });
  const action = page.locator('[data-id="classes/sgpromotion:MaterializeSpecDraft"]');
  await expect(action.locator('.node-header strong')).toHaveText('MaterializeSpecDraft');
  await expect(action.locator('.node-namespace')).toHaveText('sgpromotion');
  await expect(action.locator('.node-header strong')).toHaveAttribute('title', 'sgpromotion:MaterializeSpecDraft');
  await expect(action.locator('.node-port')).toContainText('target: Ref<Target>');
  const geometry = await action.evaluate((node) => {
    const bounds = node.getBoundingClientRect();
    const kind = node.querySelector('.node-kind')!.getBoundingClientRect();
    const badge = node.querySelector('.node-namespace')!.getBoundingClientRect();
    const name = node.querySelector('strong')!.getBoundingClientRect();
    return { separate: kind.right <= badge.left, within: badge.right <= bounds.right,
      aboveName: badge.bottom <= name.top, badgeAtTop: badge.top < name.top };
  });
  expect(geometry).toEqual({ separate: true, within: true, aboveName: true, badgeAtTop: true });
  const relationship = page.locator('[data-id="relations/sgpromotion:targets"]');
  await expect(relationship.locator('.node-header strong')).toHaveText('targets');
  await expect(relationship.locator('.node-namespace')).toHaveText('sgpromotion');
  await expect(relationship.locator('.node-port')).toHaveCount(3);
  const unloaded = page.locator(`[data-id="external/classes/${external}:Base"]`);
  await expect(unloaded.locator('.node-namespace')).toHaveAttribute('title', external);
  expect(await unloaded.locator('.node-namespace').evaluate((element) => element.scrollWidth > element.clientWidth)).toBe(true);
  const externalGeometry = await unloaded.evaluate((node) => {
    const bounds = node.getBoundingClientRect();
    const kind = node.querySelector('.node-kind')!.getBoundingClientRect();
    const badge = node.querySelector('.node-namespace')!.getBoundingClientRect();
    return { separate: kind.right <= badge.left, within: badge.right <= bounds.right };
  });
  expect(externalGeometry).toEqual({ separate: true, within: true });
  const state = page.locator('[data-id="stateMachines/sgpromotion:Review/states/draft"]');
  await expect(state.locator('.node-header strong')).toHaveText('draft');
  await expect(state.locator('.node-namespace')).toHaveCount(0);
  await page.getByLabel('Search graph').fill('sgpromotion:MaterializeSpecDraft');
  await page.getByRole('button', { name: /sgpromotion:MaterializeSpecDraft/ }).click();
  await expect(page.getByLabel('Inspector').getByRole('heading')).toHaveText('sgpromotion:MaterializeSpecDraft');
});
