import { expect, test } from '@playwright/test';
import { spawn, spawnSync, type ChildProcess } from 'node:child_process';
import { createHash } from 'node:crypto';
import { once } from 'node:events';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const compiler = process.env.ONTOLOGY_COMPILER;
const realViz = process.env.ONTOLOGY_VIZ;
const dist = process.env.ONTOLOGY_VIEWER_DIST;
const fixture = path.resolve('../../Examples/package-visualization/domain-ontology-package.yaml');
const tempRoot = process.env.ONTOLOGY_VIEWER_TEST_TMP || os.tmpdir();
const digest = (value: string) => `sha256:${createHash('sha256').update(value).digest('hex')}`;

async function launch(source: string, mode: '--package' | '--profile' = '--package', viz = realViz) {
  if (!compiler || !viz || !dist) throw new Error('Set ONTOLOGY_COMPILER, ONTOLOGY_VIZ and ONTOLOGY_VIEWER_DIST');
  const child = spawn(process.execPath, [path.resolve('workspace.mjs'), mode, source, '--ontologyc', compiler,
    '--ontologyviz', viz, '--dist', dist], { env: process.env, stdio: ['ignore', 'pipe', 'pipe'] });
  let log = '';
  const url = await new Promise<string>((resolve, reject) => {
    const timer = setTimeout(() => { child.kill('SIGTERM'); reject(new Error(`Workspace startup timed out: ${log}`)); }, 15000);
    child.stdout?.on('data', (data: Buffer) => {
      log += data.toString();
      const match = log.match(/http:\/\/127\.0\.0\.1:\d+\//);
      if (match) { clearTimeout(timer); resolve(match[0]); }
    });
    child.stderr?.on('data', (data: Buffer) => { log += data.toString(); });
    child.on('exit', (code) => { clearTimeout(timer); reject(new Error(`Workspace exited ${code}: ${log}`)); });
  });
  const html = await (await fetch(url)).text();
  const token = html.match(/name="ontology-session" content="([a-f0-9]+)"/)?.[1];
  if (!token) { child.kill('SIGTERM'); throw new Error('Missing workspace token'); }
  const headers = { 'x-ontology-token': token };
  return {
    child, url, headers,
    get: () => fetch(`${url}api/session`, { headers }),
    save: (expectedDigest: string, content: string) => fetch(`${url}api/save`, { method: 'POST',
      headers: { ...headers, origin: new URL(url).origin, 'content-type': 'application/json' },
      body: JSON.stringify({ expectedDigest, content }) }),
  };
}

async function stop(child: ChildProcess) {
  if (child.exitCode === null && child.signalCode === null) {
    const exited = once(child, 'exit');
    child.kill('SIGTERM');
    await exited;
  }
}

test('blocks retargeted root symlinks and malformed Unicode without losing a browser draft', async ({ page }) => {
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-root-link-'));
  const a = path.join(directory, 'a.yaml'), b = path.join(directory, 'b.yaml'), link = path.join(directory, 'selected.yaml');
  const original = await fs.readFile(fixture, 'utf8');
  const other = original.replace('A proposal submitted for review.', 'Other target.');
  await fs.writeFile(a, original); await fs.writeFile(b, other); await fs.symlink('a.yaml', link);
  const server = await launch(link);
  try {
    const snapshot = await (await server.get()).json();
    const invalid = await server.save(snapshot.source.digest, 'a\ud800b');
    expect(invalid.status).toBe(400);
    expect(await fs.readFile(a, 'utf8')).toBe(original);
    await page.goto(server.url);
    const editor = page.getByLabel('Ontology YAML source');
    await expect(editor).toHaveValue(/A proposal submitted for review/);
    const draft = original.replace('A proposal submitted for review.', 'Human draft.');
    await editor.fill(draft);
    await fs.unlink(link); await fs.symlink('b.yaml', link);
    await expect(page.getByRole('alert')).toContainText('points elsewhere');
    await expect(editor).toHaveValue(draft);
    await expect(page.getByRole('button', { name: 'Save YAML' })).toBeDisabled();
    const read = await server.get();
    expect(read.status).toBe(409);
    expect((await read.json()).code).toBe('input_changed');
    const save = await server.save(snapshot.source.digest, draft);
    expect(save.status).toBe(409);
    expect((await save.json()).code).toBe('input_changed');
    expect(await fs.readFile(a, 'utf8')).toBe(original);
    expect(await fs.readFile(b, 'utf8')).toBe(other);
    await fs.unlink(link); await fs.symlink('a.yaml', link);
    await expect(page.getByRole('alert')).toHaveCount(0);
    await expect(editor).toHaveValue(draft);
    await expect(page.getByRole('button', { name: 'Save YAML' })).toBeEnabled();
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('detects retargeted import symlinks instead of caching an unrelated package', async () => {
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-import-link-'));
  const root = path.join(directory, 'root.yaml'), a = path.join(directory, 'a.yaml'), b = path.join(directory, 'b.yaml');
  const link = path.join(directory, 'current.yaml'), profile = path.join(directory, 'view.json');
  const motivation = await fs.readFile(path.resolve('../../SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml'));
  const events = await fs.readFile(path.resolve('../../SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml'), 'utf8');
  await fs.writeFile(root, motivation); await fs.writeFile(a, events);
  await fs.writeFile(b, events.replace('Role reading of a registered RecordedEvent', 'Other import target'));
  await fs.symlink('a.yaml', link);
  await fs.writeFile(profile, JSON.stringify({ schemaVersion: 1, package: 'root.yaml', view: 'relations', imports: ['current.yaml'],
    expand: ['eventcore:Interpretation', 'eventcore:RecordedEvent'] }));
  const server = await launch(profile, '--profile');
  try {
    expect((await server.get()).status).toBe(200);
    await fs.unlink(link); await fs.symlink('b.yaml', link);
    const read = await server.get();
    expect(read.status).toBe(409);
    expect((await read.json()).code).toBe('input_changed');
    await fs.unlink(link); await fs.symlink('a.yaml', link);
    const restored = await server.get();
    expect(restored.status).toBe(200);
    expect((await restored.json()).graph.classes.find((item: { fqid: string }) => item.fqid === 'eventcore:Interpretation').description)
      .toContain('Role reading of a registered RecordedEvent');
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('keeps the selected unresolved protocol when a same-named class also exists', async ({ page }) => {
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-node-identity-'));
  const source = path.join(directory, 'package.yaml');
  const original = (await fs.readFile(fixture, 'utf8'))
    .replace('    - id: specgraph.foundation', '    - id: example.shared\n      namespace: ext\n      version: 0.1.0\n    - id: specgraph.foundation')
    .replace('extends: sg:DomainEntity\n      implements: [Reviewable]', 'extends: ext:Shared\n      implements: [ext:Shared]');
  await fs.writeFile(source, original);
  const server = await launch(source);
  try {
    await page.goto(server.url);
    const inspector = page.getByLabel('Inspector');
    const protocol = page.locator('.react-flow__node').filter({ hasText: 'ext:Shared' }).last();
    await expect(page.locator('.react-flow__node').filter({ hasText: 'ext:Shared' })).toHaveCount(2);
    await protocol.click({ force: true });
    await expect(inspector).toContainText('unloaded reference (protocol)');
    await fs.writeFile(source, original.replace('A proposal submitted for review.', 'Updated description.'));
    await expect(page.getByLabel('Ontology YAML source')).toHaveValue(/Updated description/);
    await expect(inspector).toContainText('unloaded reference (protocol)');

    // Both placeholders have the same label, origin and kind. Only their IDs
    // distinguish the class filter from the protocol filter.
    await page.locator('.filter-panel summary').click();
    const protocols = page.getByRole('checkbox', { name: 'Protocols', exact: true });
    const classes = page.getByRole('checkbox', { name: 'Classes', exact: true });
    await protocols.uncheck();
    await expect(page.locator('[data-id="external/classes/ext:Shared"]')).toBeVisible();
    await expect(inspector.getByRole('status')).toContainText('outside the active filters');
    await classes.uncheck();
    await protocols.check();
    await expect(page.locator('[data-id="external/protocols/ext:Shared"]')).toBeVisible();
    await expect(inspector.getByRole('status')).toHaveCount(0);

    await page.getByLabel('Search graph').fill('ext:Shared');
    await page.getByRole('button', { name: /ext:Shared/ }).click();
    await protocols.uncheck();
    await expect(inspector.getByRole('status')).toContainText('outside the active filters');
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('retries a transient visualizer failure without a source edit', async () => {
  if (!realViz) throw new Error('Set ONTOLOGY_VIZ');
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-viz-retry-'));
  const source = path.join(directory, 'package.yaml'), wrapper = path.join(directory, 'visualizer'), calls = path.join(directory, 'calls');
  await fs.copyFile(fixture, source);
  await fs.writeFile(wrapper, `#!/usr/bin/env node\nconst f=require('fs'),c=require('child_process'),p=${JSON.stringify(calls)};` +
    `const n=f.existsSync(p)?Number(f.readFileSync(p,'utf8'))+1:1;f.writeFileSync(p,String(n));` +
    `if(n===1){console.error('temporary failure');process.exit(1)}const r=c.spawnSync(${JSON.stringify(realViz)},process.argv.slice(2),{stdio:'inherit'});process.exit(r.status??1);\n`, { mode: 0o755 });
  const server = await launch(source, '--package', wrapper);
  try {
    const first = await (await server.get()).json();
    expect(first.graph).toBeNull();
    expect(first.graphError).toContain('temporary failure');
    const second = await (await server.get()).json();
    expect(second.graph.id).toBe('example.review');
    expect(await fs.readFile(calls, 'utf8')).toBe('2');
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('rejects graph bytes from a different import and retries on unchanged inputs', async () => {
  if (!realViz) throw new Error('Set ONTOLOGY_VIZ');
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-viz-mismatch-'));
  const root = path.join(directory, 'root.yaml'), a = path.join(directory, 'a.yaml'), b = path.join(directory, 'b.yaml');
  const link = path.join(directory, 'current.yaml'), profile = path.join(directory, 'view.json');
  const wrapper = path.join(directory, 'visualizer'), calls = path.join(directory, 'calls'), wrong = path.join(directory, 'wrong');
  await fs.copyFile(path.resolve('../../SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml'), root);
  const events = await fs.readFile(path.resolve('../../SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml'), 'utf8');
  await fs.writeFile(a, events); await fs.writeFile(b, events.replace('Role reading of a registered RecordedEvent', 'Different target'));
  await fs.symlink('b.yaml', link);
  await fs.writeFile(profile, JSON.stringify({ schemaVersion: 1, package: 'root.yaml', view: 'relations', imports: ['current.yaml'],
    expand: ['eventcore:Interpretation', 'eventcore:RecordedEvent'] }));
  const generated = spawnSync(realViz, ['--profile', profile, '--format', 'json', '--out', wrong], { encoding: 'utf8', env: process.env });
  expect(generated.status, generated.stderr).toBe(0);
  await fs.unlink(link); await fs.symlink('a.yaml', link);
  await fs.writeFile(wrapper, `#!/usr/bin/env node\nconst f=require('fs'),c=require('child_process'),p=${JSON.stringify(calls)};` +
    `const n=f.existsSync(p)?Number(f.readFileSync(p,'utf8'))+1:1;f.writeFileSync(p,String(n));` +
    `if(n===1){f.copyFileSync(${JSON.stringify(path.join(wrong, 'ontology.graph.json'))},require('path').join(process.argv[process.argv.indexOf('--out')+1],'ontology.graph.json'));process.exit(0)}` +
    `const r=c.spawnSync(${JSON.stringify(realViz)},process.argv.slice(2),{stdio:'inherit'});process.exit(r.status??1);\n`, { mode: 0o755 });
  const server = await launch(profile, '--profile', wrapper);
  try {
    const first = await (await server.get()).json();
    expect(first.graph).toBeNull();
    expect(first.graphError).toContain('does not match the selected source bytes');
    const second = await (await server.get()).json();
    expect(second.graph.classes.find((item: { fqid: string }) => item.fqid === 'eventcore:Interpretation').description)
      .toContain('Role reading of a registered RecordedEvent');
    expect(await fs.readFile(calls, 'utf8')).toBe('2');
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('treats an overlapping save and snapshot as retryable rather than a server failure', async ({ page }) => {
  if (!realViz) throw new Error('Set ONTOLOGY_VIZ');
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-snapshot-race-'));
  const source = path.join(directory, 'package.yaml'), wrapper = path.join(directory, 'visualizer');
  const calls = path.join(directory, 'calls'), started = path.join(directory, 'started'), release = path.join(directory, 'release');
  const original = await fs.readFile(fixture, 'utf8');
  await fs.writeFile(source, original);
  await fs.writeFile(wrapper, `#!/usr/bin/env node\nconst f=require('fs'),c=require('child_process'),p=${JSON.stringify(calls)};` +
    `const n=f.existsSync(p)?Number(f.readFileSync(p,'utf8'))+1:1;f.writeFileSync(p,String(n));` +
    `const run=()=>{const r=c.spawnSync(${JSON.stringify(realViz)},process.argv.slice(2),{stdio:'inherit'});process.exit(r.status??1)};` +
    `if(n!==2)run();else{f.writeFileSync(${JSON.stringify(started)},'1');const w=f.watch(${JSON.stringify(directory)},()=>{` +
    `if(f.existsSync(${JSON.stringify(release)})){w.close();run()}});if(f.existsSync(${JSON.stringify(release)})){w.close();run()}setTimeout(()=>process.exit(2),10000).unref()}\n`, { mode: 0o755 });
  const server = await launch(source, '--package', wrapper);
  try {
    expect((await server.get()).status).toBe(200);
    const intermediate = `${original}\n# intermediate\n`;
    await fs.writeFile(source, intermediate);
    const pending = server.get();
    await expect.poll(() => fs.stat(started).then(() => true, () => false)).toBe(true);
    const saved = await server.save(digest(intermediate), `${intermediate}# saved\n`);
    expect(saved.status).toBe(200);
    await fs.writeFile(release, 'continue');
    const raced = await pending;
    expect(raced.status).toBe(409);
    expect(await raced.json()).toMatchObject({ code: 'snapshot_changed', retryable: true });
    expect((await server.get()).status).toBe(200);

    await page.goto(server.url);
    await expect(page.getByLabel('Ontology YAML source')).toHaveValue(/# saved/);
    let simulated = false;
    await page.route('**/api/session', async (route) => {
      if (!simulated) {
        simulated = true;
        await route.fulfill({ status: 409, contentType: 'application/json',
          body: JSON.stringify({ code: 'snapshot_changed', retryable: true, error: 'Source changed while checking' }) });
      } else await route.continue();
    });
    const waiting = page.getByRole('status').filter({ hasText: 'waiting for a stable snapshot' });
    await expect(waiting).toBeVisible();
    await expect(page.getByRole('alert')).toHaveCount(0);
    await expect(waiting).toHaveCount(0);
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('keeps the selected mixed line ending through delete, undo, redo and save', async ({ page }) => {
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-edit-eol-'));
  const source = path.join(directory, 'package.yaml');
  const original = `# First\r\n\n${await fs.readFile(fixture, 'utf8')}`;
  await fs.writeFile(source, original);
  const server = await launch(source);
  try {
    await page.goto(server.url);
    const editor = page.getByLabel('Ontology YAML source');
    await expect(editor).toHaveValue(/^# First\n\napiVersion/);
    await editor.focus();
    await editor.evaluate((element: HTMLTextAreaElement) => element.setSelectionRange(7, 8));
    await page.keyboard.press('Backspace');
    await expect(editor).toHaveValue(/^# First\napiVersion/);
    const modifier = process.platform === 'darwin' ? 'Meta' : 'Control';
    await page.keyboard.press(`${modifier}+z`);
    await expect(editor).toHaveValue(/^# First\n\napiVersion/);
    await page.keyboard.press(`${modifier}+Shift+z`);
    await expect(editor).toHaveValue(/^# First\napiVersion/);
    await page.getByRole('button', { name: 'Save YAML' }).click();
    await expect.poll(() => fs.readFile(source, 'utf8')).toBe(original.replace('# First\r\n\n', '# First\n'));
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});

test('preserves an ambiguous draft and disables save when no edit range is reported', async ({ page }) => {
  const directory = await fs.mkdtemp(path.join(tempRoot, 'ontology-edit-ambiguous-'));
  const source = path.join(directory, 'package.yaml');
  const original = `# First\r\n\n${await fs.readFile(fixture, 'utf8')}`;
  await fs.writeFile(source, original);
  const server = await launch(source);
  try {
    await page.goto(server.url);
    const editor = page.getByLabel('Ontology YAML source');
    await expect(editor).toHaveValue(/^# First\n\napiVersion/);
    await editor.evaluate((element: HTMLTextAreaElement) => {
      const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')?.set;
      setter?.call(element, element.value.replace('# First\n\n', '# First\n'));
      element.dispatchEvent(new Event('input', { bubbles: true }));
    });
    await expect(editor).toHaveValue(/^# First\napiVersion/);
    await expect(page.getByRole('alert')).toContainText('line endings for this edit are ambiguous');
    await expect(page.getByRole('button', { name: 'Save YAML' })).toBeDisabled();
    expect(await fs.readFile(source, 'utf8')).toBe(original);
  } finally { await stop(server.child); await fs.rm(directory, { recursive: true, force: true }); }
});
