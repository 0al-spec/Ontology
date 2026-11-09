export type JsonObject = Record<string, unknown>;

export interface SourceLocation {
  id: string;
  version: string;
  sourceDigest: string;
  sourceByteDigest: string;
  pointer: string;
}

export type Declaration = JsonObject & { id: string; fqid: string; source: SourceLocation };
type ClassField = JsonObject & { source?: SourceLocation };
type ClassDeclaration = Declaration & { fields?: ClassField[] };
export type Relation = Declaration & { domain: string; range: string | { oneOf: string[] } };
export type FoundationCatalog = {
  id: string; version: string; alias: string; catalogByteDigest: string; policyBases: string[]; catalog: JsonObject;
};
export interface Projection {
  schemaVersion: 'ontology.diagram-projection/v1';
  id: string;
  namespace: string;
  version: string;
  view: 'full' | 'relations';
  sources: JsonObject[];
  imports: JsonObject[];
  externalImports?: JsonObject[];
  foundationCatalogs?: FoundationCatalog[];
  classes: ClassDeclaration[];
  relations: Relation[];
  protocols: Declaration[];
  policies: Declaration[];
  stateMachines: Declaration[];
}

/** Foundation imports may use their compiler-defined default namespace. */
export function importNamespace(entry: JsonObject): string {
  if (typeof entry.namespace === 'string' && entry.namespace) return entry.namespace;
  if (entry.id === 'ontology.foundation') return 'ont';
  if (entry.id === 'specgraph.foundation') return 'sg';
  return '';
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

function samePackageSource(packageSource: JsonObject | SourceLocation, source: SourceLocation): boolean {
  return packageSource.id === source.id && packageSource.version === source.version &&
    packageSource.sourceDigest === source.sourceDigest && packageSource.sourceByteDigest === source.sourceByteDigest;
}

function pointerComponent(id: string): string {
  return id.replaceAll('~', '~0').replaceAll('/', '~1');
}

function classes(value: unknown): ClassDeclaration[] {
  return declarations(value, 'classes').map(({ fields, ...owner }) => {
    if (owner.source.pointer !== `/spec/classes/${pointerComponent(owner.id)}`) {
      throw new Error(`${owner.fqid}: source pointer does not match the class`);
    }
    if (fields === undefined) return owner;
    const path = `${owner.fqid}.fields`;
    const parsed = objects(fields, path).map(({ source, ...field }, index) => {
      if (source === undefined) return field;
      const id = text(field.id, `${path}[${index}].id`);
      const sourcePath = `${path}.${id}.source`;
      const fieldSource = location(source, sourcePath);
      if (!samePackageSource(owner.source, fieldSource)) {
        throw new Error(`${sourcePath} does not match the owning class package, version or digests`);
      }
      if (fieldSource.pointer !== `${owner.source.pointer}/fields/${pointerComponent(id)}`) {
        throw new Error(`${sourcePath}.pointer does not match the field`);
      }
      return { ...field, source: fieldSource };
    });
    return { ...owner, fields: parsed };
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

function foundationCatalogs(value: unknown, imports: JsonObject[], external: JsonObject[]): FoundationCatalog[] {
  const seen = new Set<string>();
  return objects(value, 'foundationCatalogs').map((entry, index) => {
    const path = `foundationCatalogs[${index}]`;
    const id = text(entry.id, `${path}.id`), version = text(entry.version, `${path}.version`);
    const alias = text(entry.alias, `${path}.alias`);
    if (seen.has(alias)) throw new Error(`${path}: duplicate alias ${alias}`);
    seen.add(alias);
    const candidates: JsonObject[] = [...imports.map((item) => ({ ...item, alias: importNamespace(item) })), ...external];
    const matches = candidates
      .filter((item) => item.id === id && item.version === version && item.alias === alias);
    if (matches.length !== 1) throw new Error(`${path}: foundation identity is not an exact import binding`);
    if (!(id === 'ontology.foundation' && ['0.1.0', '0.2.0'].includes(version)) &&
        !(id === 'specgraph.foundation' && version === '0.1.0')) throw new Error(`${path}: unsupported foundation identity`);
    const catalog = object(entry.catalog, `${path}.catalog`);
    if (catalog.schemaVersion !== 'ontology.foundation-model/v1' || catalog.id !== 'ontology.foundation' ||
        catalog.version !== version || catalog.namespace !== 'ont') throw new Error(`${path}: mismatched model identity`);
    const source = object(catalog.source, `${path}.catalog.source`);
    if (!/^[0-9a-f]{64}$/.test(text(source.sha256, `${path}.catalog.source.sha256`))) throw new Error(`${path}: invalid source digest`);
    text(source.path, `${path}.catalog.source.path`); text(source.revision, `${path}.catalog.source.revision`);
    for (const section of ['classes', 'protocols']) {
      const declarations = object(catalog[section], `${path}.catalog.${section}`);
      for (const [name, declaration] of Object.entries(declarations)) {
        text(name, `${path}.${section}.name`);
        text(object(declaration, `${path}.${section}.${name}`).declaration, `${path}.${section}.${name}.declaration`);
      }
    }
    if (!Array.isArray(entry.policyBases)) throw new Error(`${path}.policyBases must be an array`);
    const policyBases = entry.policyBases.map((item, i) => text(item, `${path}.policyBases[${i}]`));
    return { id, version, alias, catalogByteDigest: digest(entry.catalogByteDigest, `${path}.catalogByteDigest`), policyBases, catalog };
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
  const imports = objects(graph.imports, 'imports');
  const externalImports = graph.externalImports === undefined ? undefined : objects(graph.externalImports, 'externalImports');
  const externalIdentities = new Set<string>();
  for (const [index, entry] of (externalImports || []).entries()) {
    const path = `externalImports[${index}]`;
    const id = text(entry.id, `${path}.id`);
    const version = text(entry.version, `${path}.version`);
    const alias = text(entry.alias, `${path}.alias`);
    if (!/^[a-z][a-z0-9-]*$/.test(alias)) throw new Error(`${path}: invalid alias ${alias}`);
    if (aliases.has(alias) || imports.some((item) => importNamespace(item) === alias)) throw new Error(`${path}: duplicate alias ${alias}`);
    if ([...sources, ...imports].some((item) => item.id === id && item.version === version)) throw new Error(`${path}: package is already bound`);
    const identity = `${id}@${version}`;
    if (externalIdentities.has(identity)) throw new Error(`${path}: duplicate package identity ${identity}`);
    externalIdentities.add(identity);
    aliases.add(alias);
  }
  const result: Projection = {
    schemaVersion: graph.schemaVersion,
    id, namespace, version,
    view: graph.view,
    sources, imports, ...(externalImports ? { externalImports } : {}),
    ...(graph.foundationCatalogs === undefined ? {} : { foundationCatalogs: foundationCatalogs(graph.foundationCatalogs, imports, externalImports || []) }),
    classes: classes(graph.classes), relations: relations(graph.relations),
    protocols: declarations(graph.protocols, 'protocols'), policies: declarations(graph.policies, 'policies'),
    stateMachines: declarations(graph.stateMachines, 'stateMachines'),
  };
  for (const [section, records] of Object.entries({ classes: result.classes, relations: result.relations, protocols: result.protocols,
    policies: result.policies, stateMachines: result.stateMachines })) {
    for (const record of records) {
      const source = record.source;
      if (!source.pointer.startsWith(`/spec/${section}/`)) throw new Error(`${record.fqid}: source pointer does not match ${section}`);
      if (!sources.some((item) => samePackageSource(item, source) &&
          (section !== 'classes' || record.fqid === `${item.alias}:${record.id}`))) {
        throw new Error(`${record.fqid}: source does not match a loaded package`);
      }
    }
  }
  return result;
}
