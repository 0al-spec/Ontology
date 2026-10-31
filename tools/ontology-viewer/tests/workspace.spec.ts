import { expect, test } from '@playwright/test';
import { spawn, type ChildProcess } from 'node:child_process';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

async function start(source: string, mode: '--package' | '--profile' = '--package'): Promise<{ process: ChildProcess; url: string }> {
  const compiler = process.env.ONTOLOGY_COMPILER;
  const viz = process.env.ONTOLOGY_VIZ;
  const dist = process.env.ONTOLOGY_VIEWER_DIST;
  if (!compiler || !viz || !dist) throw new Error('Set ONTOLOGY_COMPILER, ONTOLOGY_VIZ and ONTOLOGY_VIEWER_DIST');
  const child = spawn(process.execPath, [path.resolve('workspace.mjs'), mode, source, '--ontologyc', compiler,
    '--ontologyviz', viz, '--dist', dist], { env: process.env, stdio: ['ignore', 'pipe', 'pipe'] });
  let log = '';
  const url = await new Promise<string>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Workspace startup timed out: ${log}`)), 15000);
    child.stdout?.on('data', (data: Buffer) => {
      log += data.toString();
      const match = log.match(/http:\/\/127\.0\.0\.1:\d+\//);
      if (match) { clearTimeout(timer); resolve(match[0]); }
    });
    child.stderr?.on('data', (data: Buffer) => { log += data.toString(); });
    child.on('exit', (code) => { clearTimeout(timer); reject(new Error(`Workspace exited ${code}: ${log}`)); });
  });
  return { process: child, url };
}

test('edits shared YAML, keeps comments and line endings, refreshes external changes and protects drafts', async ({ page }) => {
  const directory = await fs.mkdtemp(path.join(process.env.ONTOLOGY_VIEWER_TEST_TMP || os.tmpdir(), 'ontology-workspace-test-'));
  const source = path.join(directory, 'package.yaml');
  const fixture = await fs.readFile(path.resolve('../../Examples/package-visualization/domain-ontology-package.yaml'), 'utf8');
  const original = `\ufeff# Keep this human comment\r\n${fixture.replace(/\n/g, '\r\n')}`;
  await fs.writeFile(source, original);
  const server = await start(source);
  try {
    const forbidden = await fetch(`${server.url}api/session`);
    expect(forbidden.status).toBe(403);
    const html = await (await fetch(server.url)).text();
    const token = html.match(/name="ontology-session" content="([a-f0-9]+)"/)?.[1];
    expect(token).toBeTruthy();
    const headers = { 'content-type': 'application/json', 'x-ontology-token': token!, origin: new URL(server.url).origin };
    const evil = await fetch(`${server.url}api/session`, { headers: { 'x-ontology-token': token!, origin: 'https://example.invalid' } });
    expect(evil.status).toBe(403);
    const session = await (await fetch(`${server.url}api/session`, { headers: { 'x-ontology-token': token! } })).json();
    const before = await fs.stat(source);
    const unchanged = await fetch(`${server.url}api/save`, { method: 'POST', headers,
      body: JSON.stringify({ expectedDigest: session.source.digest, content: session.source.content }) });
    expect((await unchanged.json()).saved).toBe(false);
    expect((await fs.stat(source)).mtimeMs).toBe(before.mtimeMs);
    const stale = await fetch(`${server.url}api/save`, { method: 'POST', headers,
      body: JSON.stringify({ expectedDigest: `sha256:${'0'.repeat(64)}`, content: 'must not be written' }) });
    expect(stale.status).toBe(409);
    expect(await fs.readFile(source, 'utf8')).toBe(original);
    await page.goto(server.url);
    const editor = page.getByLabel('Ontology YAML source');
    await expect(editor).toHaveValue(/# Keep this human comment/);
    await expect(page.getByRole('heading', { name: 'example.review' })).toBeVisible();
    await editor.fill((await editor.inputValue()).replace('A proposal submitted for review.', 'A proposal with an improved description.'));
    await page.getByRole('button', { name: 'Save YAML' }).click();
    const expected = original.replace('A proposal submitted for review.', 'A proposal with an improved description.');
    await expect.poll(() => fs.readFile(source, 'utf8')).toBe(expected);
    await page.getByLabel('Search graph').fill('Proposal');
    await page.getByRole('button', { name: /review:Proposal/i }).click();
    await expect(page.getByLabel('Inspector')).toContainText('A proposal with an improved description.');

    await editor.fill((await editor.inputValue()).replace('range: Evidence', 'range: Missing'));
    await page.getByRole('button', { name: 'Save YAML' }).click();
    await expect(page.getByText(/Graph is stale/)).toBeVisible();
    await expect(page.locator('.diagnostic').filter({ hasText: 'relation.range.unresolved' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'example.review' })).toBeVisible();
    await editor.fill((await editor.inputValue()).replace('range: Missing', 'range: Evidence'));
    await page.getByRole('button', { name: 'Save YAML' }).click();
    await expect(page.getByText(/Graph is stale/)).toHaveCount(0);
    const selectedNode = page.locator('[data-id="classes/review:Proposal"]');
    const bounds = await selectedNode.boundingBox();
    if (!bounds) throw new Error('Selected node is not visible');
    await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
    await page.mouse.down();
    await page.mouse.move(bounds.x + bounds.width / 2 + 20, bounds.y + bounds.height / 2 + 16, { steps: 5 });
    await page.mouse.up();
    const position = await selectedNode.evaluate((node) => getComputedStyle(node).transform);

    const external = expected.replace('Evidence cited by a proposal.', 'Evidence changed externally.');
    await fs.writeFile(source, external);
    await expect(editor).toHaveValue(/Evidence changed externally\./);
    await expect(page.getByLabel('Inspector')).toContainText('A proposal with an improved description.');
    await expect.poll(() => selectedNode.evaluate((node) => getComputedStyle(node).transform)).toBe(position);
    await editor.fill((await editor.inputValue()).replace('A proposal with an improved description.', 'Unsaved human draft.'));
    const secondExternal = external.replace('Evidence changed externally.', 'Evidence changed again.');
    await fs.writeFile(source, secondExternal);
    await expect(page.getByText('Changed on disk', { exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Save YAML' })).toBeDisabled();
    await expect(editor).toHaveValue(/Unsaved human draft\./);
    expect(await fs.readFile(source, 'utf8')).toBe(secondExternal);
    await page.screenshot({ path: test.info().outputPath('workspace-conflict.png'), fullPage: true });
  } finally {
    server.process.kill('SIGTERM');
    await new Promise((resolve) => server.process.once('exit', resolve));
    await fs.rm(directory, { recursive: true, force: true });
  }
});

test('refreshes an imported package in a profile without rewriting the root source', async ({ page }) => {
  const directory = await fs.mkdtemp(path.join(process.env.ONTOLOGY_VIEWER_TEST_TMP || os.tmpdir(), 'ontology-profile-test-'));
  const root = path.join(directory, 'motivation.yaml');
  const imported = path.join(directory, 'events.yaml');
  const profile = path.join(directory, 'view.json');
  const originalRoot = await fs.readFile(path.resolve('../../SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml'));
  const originalImport = await fs.readFile(path.resolve('../../SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml'), 'utf8');
  await fs.writeFile(root, originalRoot);
  await fs.writeFile(imported, originalImport);
  await fs.writeFile(profile, JSON.stringify({ schemaVersion: 1, package: 'motivation.yaml', view: 'relations', imports: ['events.yaml'],
    expand: ['eventcore:Interpretation', 'eventcore:RecordedEvent'] }));
  const server = await start(profile, '--profile');
  try {
    await page.goto(server.url);
    await expect(page.getByRole('heading', { name: 'org.0al.motivation.core' })).toBeVisible();
    await page.getByLabel('Search graph').fill('eventcore:Interpretation');
    await page.locator('.search-results button').filter({ has: page.getByText('eventcore:Interpretation', { exact: true }) }).click();
    await expect(page.getByLabel('Inspector')).toContainText('Role reading of a registered RecordedEvent');
    await fs.writeFile(imported, originalImport.replace('Role reading of a registered RecordedEvent', 'An externally updated interpretation'));
    await expect.poll(async () => {
      await page.locator('.search-results button').filter({ has: page.getByText('eventcore:Interpretation', { exact: true }) }).click();
      return await page.getByLabel('Inspector').textContent();
    }).toContain('An externally updated interpretation');
    expect(await fs.readFile(root)).toEqual(originalRoot);
  } finally {
    server.process.kill('SIGTERM');
    await new Promise((resolve) => server.process.once('exit', resolve));
    await fs.rm(directory, { recursive: true, force: true });
  }
});
