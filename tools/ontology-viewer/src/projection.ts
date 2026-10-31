export type JsonObject = Record<string, unknown>;

export interface SourceLocation {
  id: string;
  version: string;
  sourceDigest: string;
  sourceByteDigest: string;
  pointer: string;
}

export type Declaration = JsonObject & { id: string; fqid: string; source: SourceLocation };
export type Relation = Declaration & { domain: string; range: string | { oneOf: string[] } };
export interface Projection {
  schemaVersion: 'ontology.diagram-projection/v1';
  id: string;
  namespace: string;
  version: string;
  view: 'full' | 'relations';
  sources: JsonObject[];
  imports: JsonObject[];
  classes: Declaration[];
  relations: Relation[];
  protocols: Declaration[];
  policies: Declaration[];
  stateMachines: Declaration[];
}

function object(value: unknown, path: string): JsonObject {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) throw new Error(`${path} must be an object`);
  return value as JsonObject;
}

function text(value: unknown, path: string): string {
  if (typeof value !== 'string' || value.length === 0) throw new Error(`${path} must be a nonempty string`);
  return value;
}

function objects(value: unknown, path: string): JsonObject[] {
  if (!Array.isArray(value)) throw new Error(`${path} must be an array`);
  return value.map((entry, index) => object(entry, `${path}[${index}]`));
}

function digest(value: unknown, path: string): string {
  const result = text(value, path);
  if (!/^sha256:[0-9a-f]{64}$/.test(result)) throw new Error(`${path} is invalid`);
  return result;
}

function location(value: unknown, path: string): SourceLocation {
  const entry = object(value, path);
  const sourceDigest = digest(entry.sourceDigest, `${path}.sourceDigest`);
  const sourceByteDigest = digest(entry.sourceByteDigest, `${path}.sourceByteDigest`);
  const pointer = text(entry.pointer, `${path}.pointer`);
  if (!pointer.startsWith('/spec/')) throw new Error(`${path}.pointer must address a spec declaration`);
  return { id: text(entry.id, `${path}.id`), version: text(entry.version, `${path}.version`), sourceDigest, sourceByteDigest, pointer };
}

function declarations(value: unknown, path: string): Declaration[] {
  const seen = new Set<string>();
  return objects(value, path).map((entry, index) => {
    const itemPath = `${path}[${index}]`;
    const fqid = text(entry.fqid, `${itemPath}.fqid`);
    if (seen.has(fqid)) throw new Error(`${path}: duplicate declaration ${fqid}`);
    seen.add(fqid);
    return { ...entry, id: text(entry.id, `${itemPath}.id`), fqid, source: location(entry.source, `${itemPath}.source`) };
  });
}

function relations(value: unknown): Relation[] {
  return declarations(value, 'relations').map((entry, index) => {
    const path = `relations[${index}]`;
    const domain = text(entry.domain, `${path}.domain`);
    let range: Relation['range'];
    if (typeof entry.range === 'string') {
      range = text(entry.range, `${path}.range`);
    } else {
      const choice = object(entry.range, `${path}.range`);
      if (!Array.isArray(choice.oneOf) || choice.oneOf.length === 0) throw new Error(`${path}.range.oneOf must be nonempty`);
      range = { oneOf: choice.oneOf.map((ref, index) => text(ref, `${path}.range.oneOf[${index}]`)) };
    }
    return { ...entry, domain, range };
  });
}

/** Parse only the supported version and reject malformed inputs before replacing a view. */
export function parseProjection(value: unknown): Projection {
  const graph = object(value, 'graph');
  if (graph.schemaVersion !== 'ontology.diagram-projection/v1') throw new Error('Unsupported schemaVersion');
  if (graph.view !== 'full' && graph.view !== 'relations') throw new Error('graph.view must be full or relations');
  const id = text(graph.id, 'graph.id');
  const namespace = text(graph.namespace, 'graph.namespace');
  const version = text(graph.version, 'graph.version');
  const sourceDigest = digest(graph.sourceDigest, 'graph.sourceDigest');
  const sourceByteDigest = digest(graph.sourceByteDigest, 'graph.sourceByteDigest');
  const sources = objects(graph.sources, 'sources');
  if (!sources.length) throw new Error('sources must include the root package');
  const aliases = new Set<string>();
  for (const [index, entry] of sources.entries()) {
    const path = `sources[${index}]`;
    text(entry.id, `${path}.id`); text(entry.version, `${path}.version`); text(entry.namespace, `${path}.namespace`);
    const alias = text(entry.alias, `${path}.alias`);
    if (aliases.has(alias)) throw new Error(`sources: duplicate alias ${alias}`);
    aliases.add(alias);
    digest(entry.sourceDigest, `${path}.sourceDigest`); digest(entry.sourceByteDigest, `${path}.sourceByteDigest`);
  }
  const root = sources[0];
  if (root.id !== id || root.version !== version || root.namespace !== namespace || root.alias !== namespace ||
      root.sourceDigest !== sourceDigest || root.sourceByteDigest !== sourceByteDigest) throw new Error('sources[0] does not match the root package');
  const result: Projection = {
    schemaVersion: graph.schemaVersion,
    id, namespace, version,
    view: graph.view,
    sources, imports: objects(graph.imports, 'imports'),
    classes: declarations(graph.classes, 'classes'), relations: relations(graph.relations),
    protocols: declarations(graph.protocols, 'protocols'), policies: declarations(graph.policies, 'policies'),
    stateMachines: declarations(graph.stateMachines, 'stateMachines'),
  };
  for (const [section, records] of Object.entries({ classes: result.classes, relations: result.relations, protocols: result.protocols,
    policies: result.policies, stateMachines: result.stateMachines })) {
    for (const record of records) {
      const source = record.source;
      if (!source.pointer.startsWith(`/spec/${section}/`)) throw new Error(`${record.fqid}: source pointer does not match ${section}`);
      if (!sources.some((item) => item.id === source.id && item.version === source.version &&
          item.sourceDigest === source.sourceDigest && item.sourceByteDigest === source.sourceByteDigest)) {
        throw new Error(`${record.fqid}: source does not match a loaded package`);
      }
    }
  }
  return result;
}
