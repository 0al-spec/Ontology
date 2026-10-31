import { createServer } from 'node:http';
import { createHash, randomBytes } from 'node:crypto';
import { execFile } from 'node:child_process';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const directory = path.dirname(fileURLToPath(import.meta.url));
const hash = (data) => `sha256:${createHash('sha256').update(data).digest('hex')}`;
const decode = (data) => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(data);
const run = (command, args) => new Promise((resolve) => {
  execFile(command, args, { timeout: 30000, maxBuffer: 4 * 1024 * 1024 }, (error, stdout, stderr) => {
    resolve({ code: error ? (typeof error.code === 'number' ? error.code : -1) : 0, stdout, stderr, error: error?.message });
  });
});

class InputPathChanged extends Error {}
class SnapshotChanged extends Error {}

function optionsFromArgs(args) {
  const options = {};
  for (let index = 0; index < args.length; index += 2) {
    const key = args[index];
    if (!['--package', '--profile', '--ontologyviz', '--ontologyc', '--port', '--dist'].includes(key) || !args[index + 1] || options[key]) {
      throw new Error(`Invalid or repeated option: ${key}`);
    }
    options[key] = args[index + 1];
  }
  if (Boolean(options['--package']) === Boolean(options['--profile'])) throw new Error('Provide exactly one --package or --profile');
  const port = Number(options['--port'] || 0);
  if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('Invalid port');
  return { package: options['--package'], profile: options['--profile'], viz: options['--ontologyviz'] || 'ontologyviz',
    compiler: options['--ontologyc'] || 'ontologyc', port, dist: options['--dist'] || path.join(directory, 'dist') };
}

async function resolveInputs(options) {
  if (options.package) {
    const rootPath = path.resolve(options.package);
    return { rootPath, root: await fs.realpath(rootPath), importPaths: [], imports: [], profilePath: null, profile: null, profileDigest: null };
  }
  const profilePath = path.resolve(options.profile);
  const profile = await fs.realpath(profilePath);
  const bytes = await fs.readFile(profile);
  const doc = JSON.parse(decode(bytes));
  if (typeof doc.package !== 'string' || !Array.isArray(doc.imports || []) || (doc.imports || []).some((item) => typeof item !== 'string')) {
    throw new Error('Invalid profile package or imports');
  }
  const rootPath = path.resolve(path.dirname(profile), doc.package);
  const importPaths = (doc.imports || []).map((item) => path.resolve(path.dirname(profile), item));
  const root = await fs.realpath(rootPath);
  const imports = await Promise.all(importPaths.map((item) => fs.realpath(item)));
  return { rootPath, root, importPaths, imports, profilePath, profile, profileDigest: hash(bytes) };
}

async function readBody(request) {
  const parts = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 8 * 1024 * 1024) throw new Error('Request is too large');
    parts.push(chunk);
  }
  return JSON.parse(Buffer.concat(parts).toString('utf8'));
}

function json(response, status, value) {
  response.writeHead(status, { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' });
  response.end(JSON.stringify(value));
}

/** Start an isolated local workspace. Only the explicitly selected root is writable. */
export async function startWorkspace(options) {
  const inputs = await resolveInputs(options);
  const dist = await fs.realpath(options.dist || path.join(directory, 'dist'));
  const index = await fs.readFile(path.join(dist, 'index.html'), 'utf8');
  const scratch = await fs.mkdtemp(path.join(os.tmpdir(), 'ontology-workspace-'));
  const token = randomBytes(32).toString('hex');
  let cache = null;
  let refreshPromise = null;
  let saveQueue = Promise.resolve();

  async function readInputs() {
    const paths = [[inputs.rootPath, inputs.root], ...inputs.importPaths.map((item, index) => [item, inputs.imports[index]])];
    if (inputs.profile) paths.push([inputs.profilePath, inputs.profile]);
    for (const [selected, pinned] of paths) {
      let resolved;
      try { resolved = await fs.realpath(selected); }
      catch { throw new InputPathChanged('A selected input path is unavailable; restore it or restart the workspace'); }
      if (resolved !== pinned) throw new InputPathChanged('A selected input path now points elsewhere; restore it or restart the workspace');
    }
    const [root, ...imports] = await Promise.all([inputs.root, ...inputs.imports].map((item) => fs.readFile(item)));
    if (inputs.profile && hash(await fs.readFile(inputs.profile)) !== inputs.profileDigest) throw new InputPathChanged('Profile changed; restart the workspace');
    return { root, imports, key: [hash(root), ...imports.map(hash), inputs.profileDigest || ''].join('|') };
  }

  async function refresh() {
    const input = await readInputs();
    if (cache?.key === input.key) return cache.value;
    const source = { name: path.basename(inputs.root), content: decode(input.root), digest: hash(input.root) };
    const checked = await run(options.compiler, ['check', inputs.root, '--format', 'json']);
    let diagnostics = [];
    let toolError = null;
    try {
      diagnostics = JSON.parse(checked.stdout);
      if (!Array.isArray(diagnostics) || ![0, 1].includes(checked.code)) throw new Error('Unexpected compiler response');
    } catch { diagnostics = []; toolError = `Compiler unavailable: ${checked.error || checked.stderr || 'invalid diagnostics'}`; }
    const args = inputs.profile ? ['--profile', inputs.profile] : [inputs.root];
    const rendered = await run(options.viz, [...args, '--format', 'json', '--out', scratch]);
    let graph = null;
    let graphError = null;
    if (rendered.code === 0) {
      try { graph = JSON.parse(await fs.readFile(path.join(scratch, 'ontology.graph.json'), 'utf8')); }
      catch { graphError = 'Visualizer did not produce a valid graph'; }
    } else graphError = rendered.stderr || rendered.error || 'Visualizer failed';
    const current = await readInputs();
    if (current.key !== input.key) throw new SnapshotChanged('Source changed while checking; waiting for a stable snapshot');
    if (graph) {
      const expected = input.imports.map(hash).sort();
      const actual = Array.isArray(graph.sources) ? graph.sources.slice(1).map((item) => item?.sourceByteDigest).sort() : [];
      if (graph.sourceByteDigest !== source.digest || !Array.isArray(graph.sources) || graph.sources[0]?.sourceByteDigest !== source.digest ||
          actual.length !== expected.length || actual.some((digest, index) => digest !== expected[index])) {
        graph = null;
        graphError = 'Visualizer output does not match the selected source bytes';
      }
    }
    const value = { source, diagnostics, toolError, graph, graphError, graphKey: input.key };
    const invalidSource = diagnostics.some((item) => item?.severity === 'error');
    if (!toolError && ((rendered.code === 0 && graph) || (rendered.code === 1 && invalidSource))) cache = { key: input.key, value };
    return value;
  }

  function snapshot() {
    if (!refreshPromise) refreshPromise = refresh().finally(() => { refreshPromise = null; });
    return refreshPromise;
  }

  async function save(body) {
    if (typeof body?.content !== 'string' || typeof body?.expectedDigest !== 'string') return { status: 400, value: { error: 'Expected content and digest' } };
    if (!body.content.isWellFormed()) return { status: 400, value: { error: 'Content contains an unpaired UTF-16 surrogate' } };
    const before = (await readInputs()).root;
    if (hash(before) !== body.expectedDigest) return { status: 409, value: { error: 'Source changed on disk' } };
    const next = Buffer.from(body.content, 'utf8');
    if (before.equals(next)) return { status: 200, value: { saved: false, digest: hash(before) } };
    const mode = (await fs.stat(inputs.root)).mode & 0o777;
    const temp = path.join(path.dirname(inputs.root), `.ontology-edit-${randomBytes(12).toString('hex')}.tmp`);
    let created = false;
    try {
      const handle = await fs.open(temp, 'wx', mode);
      created = true;
      try { await handle.writeFile(next); await handle.chmod(mode); await handle.sync(); } finally { await handle.close(); }
      if (hash((await readInputs()).root) !== body.expectedDigest) return { status: 409, value: { error: 'Source changed on disk' } };
      await fs.rename(temp, inputs.root);
      created = false;
    } finally { if (created) await fs.rm(temp, { force: true }); }
    cache = null;
    return { status: 200, value: { saved: true, digest: hash(next) } };
  }

  const server = createServer(async (request, response) => {
    const host = `127.0.0.1:${server.address().port}`;
    const origin = `http://${host}`;
    if (request.headers.host !== host || (request.headers.origin && request.headers.origin !== origin)) return json(response, 403, { error: 'Invalid host or origin' });
    const url = new URL(request.url || '/', origin);
    try {
      if (url.pathname.startsWith('/api/')) {
        if (request.headers['x-ontology-token'] !== token) return json(response, 403, { error: 'Invalid session' });
        if (url.pathname === '/api/session' && request.method === 'GET') return json(response, 200, await snapshot());
        if (url.pathname === '/api/save' && request.method === 'POST' && request.headers.origin === origin) {
          const body = await readBody(request);
          const result = saveQueue.then(() => save(body));
          saveQueue = result.then(() => {}, () => {});
          const saved = await result;
          return json(response, saved.status, saved.value);
        }
        return json(response, 404, { error: 'Not found' });
      }
      if (request.method !== 'GET') return json(response, 404, { error: 'Not found' });
      if (url.pathname === '/') {
        response.writeHead(200, { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' });
        return response.end(index.replace('</head>', `<meta name="ontology-session" content="${token}"></head>`));
      }
      if (!url.pathname.startsWith('/assets/')) return json(response, 404, { error: 'Not found' });
      const asset = await fs.realpath(path.join(dist, url.pathname));
      if (!asset.startsWith(`${dist}${path.sep}`)) return json(response, 403, { error: 'Invalid asset' });
      const type = asset.endsWith('.js') ? 'text/javascript' : asset.endsWith('.css') ? 'text/css' : 'application/octet-stream';
      response.writeHead(200, { 'content-type': type, 'x-content-type-options': 'nosniff' });
      return response.end(await fs.readFile(asset));
    } catch (error) {
      if (error instanceof InputPathChanged) return json(response, 409, { code: 'input_changed', error: error.message });
      if (error instanceof SnapshotChanged) return json(response, 409, { code: 'snapshot_changed', retryable: true, error: error.message });
      return json(response, 500, { error: error instanceof Error ? error.message : 'Workspace error' });
    }
  });
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(options.port || 0, '127.0.0.1', resolve); });
  return { url: `http://127.0.0.1:${server.address().port}/`, token, close: async () => {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await fs.rm(scratch, { recursive: true, force: true });
  } };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv.slice(2).includes('--help')) {
      console.log('Usage: node workspace.mjs (--package file.yaml | --profile view.json) [--ontologyc path] [--ontologyviz path] [--dist dir] [--port number]');
    } else {
      const workspace = await startWorkspace(optionsFromArgs(process.argv.slice(2)));
      console.log(`Ontology workspace: ${workspace.url}`);
      for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => { void workspace.close().finally(() => process.exit(0)); });
    }
  } catch (error) { console.error(`ontology-workspace: ${error.message}`); process.exitCode = 1; }
}
