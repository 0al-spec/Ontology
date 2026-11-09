import { describe, expect, it } from 'vitest';
import { buildGraph, parseProjection } from './graph';
import { graphPackages, nodePackage } from './packages';
import { nodeOrigin } from './filters';

const digest = `sha256:${'a'.repeat(64)}`;
const source = (pointer: string) => ({
  id: 'example.test', version: '1.0.0', sourceDigest: digest, sourceByteDigest: digest, pointer,
});
const graph = {
  schemaVersion: 'ontology.diagram-projection/v1',
  id: 'example.test', version: '1.0.0', namespace: 'test', view: 'full',
  sourceDigest: digest, sourceByteDigest: digest,
  sources: [{ id: 'example.test', version: '1.0.0', namespace: 'test', alias: 'test', sourceDigest: digest, sourceByteDigest: digest }],
  imports: [{ id: 'example.external', version: '1.0.0', namespace: 'ext' }],
  classes: [
    { id: 'Proposal', fqid: 'test:Proposal', description: 'A proposal', extends: 'ext:Entity', implements: ['test:Reviewable'], lifecycle: 'Review', source: source('/spec/classes/Proposal') },
    { id: 'Evidence', fqid: 'test:Evidence', description: 'Evidence', extends: 'ext:Entity', source: source('/spec/classes/Evidence') },
  ],
  relations: [{ id: 'cites', fqid: 'test:cites', domain: 'test:Proposal', range: { oneOf: ['test:Evidence', 'ext:Record'] }, source: source('/spec/relations/cites') }],
  protocols: [{ id: 'Reviewable', fqid: 'test:Reviewable', source: source('/spec/protocols/Reviewable') }],
  policies: [{ id: 'Approval', fqid: 'test:Approval', extends: 'ext:Policy', appliesTo: ['test:Proposal'], source: source('/spec/policies/Approval') }],
  stateMachines: [{ id: 'Review', fqid: 'test:Review', states: ['draft', 'done'], transitions: [{ from: 'draft', to: 'done', command: 'test:Approve' }], source: source('/spec/stateMachines/Review') }],
};

describe('ontology graph projection adapter', () => {
  it('binds supplied foundation declarations to exact imported identity and reports provenance', () => {
    const catalog = {
      schemaVersion: 'ontology.foundation-model/v1', id: 'ontology.foundation', version: '0.1.0', namespace: 'ont',
      source: { path: 'model.md', revision: 'abc123', sha256: 'b'.repeat(64) },
      classes: { DomainEntity: { declaration: 'export interface DomainEntity {}' }, Policy: { declaration: 'export interface Policy {}' } },
      protocols: {},
    };
    const binding = { id: 'specgraph.foundation', version: '0.1.0', alias: 'base', catalogByteDigest: digest, policyBases: ['Policy'], catalog };
    const input = { ...graph, imports: [{ id: 'specgraph.foundation', version: '0.1.0', namespace: 'base' }],
      classes: [{ ...graph.classes[0], extends: 'base:DomainEntity' }],
      policies: [{ ...graph.policies[0], extends: 'base:Policy' }], foundationCatalogs: [binding] };
    const projection = parseProjection(input);
    const flow = buildGraph(projection);
    const entity = flow.nodes.find((node) => node.id === 'classes/base:DomainEntity');
    expect(entity?.data).toMatchObject({ kind: 'imported', origin: 'specgraph.foundation@0.1.0',
      foundation: { id: 'specgraph.foundation', version: '0.1.0', pointer: '/classes/DomainEntity', catalogByteDigest: digest } });
    expect(entity && nodePackage(entity)).toBe('specgraph.foundation@0.1.0');
    expect(entity && nodeOrigin(entity, input.id)).toBe('imported');
    expect(flow.nodes.find((node) => node.id === 'policies/base:Policy')?.data.foundation?.pointer).toBe('/classes/Policy');
    expect(graphPackages(flow, projection).find((item) => item.key === 'specgraph.foundation@0.1.0')?.loaded).toBe(true);
    const without = buildGraph(parseProjection({ ...input, foundationCatalogs: undefined }));
    expect(without.nodes.find((node) => node.id === 'external/classes/base:DomainEntity')?.data.kind).toBe('external');
  });

  it('rejects foundation catalogs that do not match their exact imported identity', () => {
    const catalog = { schemaVersion: 'ontology.foundation-model/v1', id: 'ontology.foundation', version: '0.2.0', namespace: 'ont',
      source: { path: 'model.md', revision: 'abc', sha256: 'b'.repeat(64) }, classes: {}, protocols: {} };
    const binding = { id: 'ontology.foundation', version: '0.2.0', alias: 'ont', catalogByteDigest: digest, policyBases: [], catalog };
    const input = { ...graph, imports: [{ id: 'ontology.foundation', version: '0.2.0', namespace: 'ont' }], foundationCatalogs: [binding] };
    expect(() => parseProjection(input)).not.toThrow();
    expect(() => parseProjection({ ...input, foundationCatalogs: [{ ...binding, alias: 'other' }] })).toThrow(/binding/);
    expect(() => parseProjection({ ...input, foundationCatalogs: [{ ...binding, catalog: { ...catalog, version: '0.1.0' } }] })).toThrow(/identity/);
    expect(() => parseProjection({ ...input, foundationCatalogs: [binding, binding] })).toThrow(/duplicate/);
    expect(() => parseProjection({ ...input, foundationCatalogs: [{ ...binding, catalogByteDigest: 'sha256:bad' }] })).toThrow(/invalid/);
  });

  it('labels an unloaded transitive dependency by exact package identity', () => {
    const missing = { id: 'example.transitive', version: '2.0.0', alias: 'dep-1234' };
    const input = {
      ...graph,
      externalImports: [missing],
      relations: [{ ...graph.relations[0], range: 'dep-1234:Missing' }],
    };
    const flow = buildGraph(parseProjection(input));
    expect(flow.nodes.find((node) => node.data.label === 'dep-1234:Missing')?.data).toMatchObject({
      kind: 'external', origin: 'example.transitive@2.0.0',
    });
  });

  it('rejects an external transitive alias that shadows an existing source', () => {
    expect(() => parseProjection({
      ...graph, externalImports: [{ id: 'example.transitive', version: '2.0.0', alias: 'test' }],
    })).toThrow(/alias/i);
  });

  it('rejects conflicting or malformed external dependency bindings', () => {
    const missing = { id: 'example.transitive', version: '2.0.0', alias: 'dep-1234' };
    expect(() => parseProjection({ ...graph, externalImports: [missing, { ...missing, alias: 'dep-5678' }] })).toThrow(/identity/i);
    expect(() => parseProjection({ ...graph, externalImports: [{ ...missing, alias: 'ext' }] })).toThrow(/alias/i);
    expect(() => parseProjection({ ...graph, externalImports: [{ ...missing, alias: 'bad:alias' }] })).toThrow(/alias/i);
    expect(() => parseProjection({ ...graph, externalImports: [{ ...missing, id: 'example.external', version: '1.0.0' }] })).toThrow(/bound/i);
    expect(() => parseProjection({ ...graph, imports: [{ id: 'ontology.foundation', version: '0.2.0' }],
      externalImports: [{ ...missing, alias: 'ont' }] })).toThrow(/alias/i);
  });

  it('labels a foundation reference when its namespace uses the compiler default', () => {
    const flow = buildGraph(parseProjection({ ...graph,
      imports: [{ id: 'ontology.foundation', version: '0.2.0' }],
      relations: [{ ...graph.relations[0], range: 'ont:DomainEntity' }],
    }));
    expect(flow.nodes.find((node) => node.data.label === 'ont:DomainEntity')?.data.origin).toBe('ontology.foundation@0.2.0');
  });

  it('retains one semantic relation for multiple oneOf edges and labels unloaded references', () => {
    const flow = buildGraph(parseProjection(graph));
    const choices = flow.edges.filter((edge) => edge.data?.semanticId === 'test:cites');
    expect(choices).toHaveLength(2);
    expect(choices.map((edge) => edge.data?.record)).toEqual([graph.relations[0], graph.relations[0]]);
    expect(choices.every((edge) => String(edge.label).includes('oneOf'))).toBe(true);
    const unloaded = flow.nodes.find((node) => node.data.label === 'ext:Record');
    expect(unloaded?.data.kind).toBe('external');
    expect(unloaded?.data.record).toBeUndefined();
    expect(flow.nodes.find((node) => node.data.label === 'test:Proposal')?.data.source?.pointer)
      .toBe('/spec/classes/Proposal');
  });

  it('represents protocol, policy, inheritance and lifecycle relationships in full view', () => {
    const flow = buildGraph(parseProjection(graph));
    expect(flow.nodes.map((node) => node.data.kind)).toEqual(expect.arrayContaining(['class', 'protocol', 'policy', 'machine', 'state']));
    expect(flow.edges.map((edge) => edge.label)).toEqual(expect.arrayContaining(['implements', 'appliesTo', 'extends', 'lifecycle', 'contains', 'test:Approve']));
  });

  it.each(['full', 'relations'])('keeps one relationship per declaration, shared actions and navigable field ports in %s view', (view) => {
    const fieldSource = source('/spec/classes/Approve/fields/evidence');
    const action = { id: 'Approve', fqid: 'test:Approve', extends: 'ont:Action', source: source('/spec/classes/Approve'),
      fields: [{ id: 'evidence', type: 'ref', target: 'test:Evidence', source: fieldSource }] };
    const first = { ...graph.relations[0], action: 'test:Approve' };
    const second = { ...first, id: 'confirms', fqid: 'test:confirms', source: source('/spec/relations/confirms') };
    const flow = buildGraph(parseProjection({ ...graph, view, classes: [...graph.classes, action], relations: [first, second] }));
    expect(flow.nodes.filter((node) => node.id.startsWith('relations/'))).toHaveLength(2);
    expect(flow.nodes.filter((node) => node.id === 'classes/test:Approve')).toHaveLength(1);
    expect(flow.nodes.find((node) => node.id === 'classes/test:Approve')?.data.isAction).toBe(true);
    expect(flow.nodes.find((node) => node.id === 'classes/test:Approve')?.data.fieldTargets?.evidence).toBe('test:Evidence');
    const roles = flow.edges.filter((edge) => edge.id.startsWith('role/test:cites/'));
    expect(roles.map((edge) => [edge.source, edge.target, edge.sourceHandle, edge.targetHandle])).toEqual([
      ['classes/test:Proposal', 'relations/test:cites', undefined, 'subject'],
      ['classes/test:Approve', 'relations/test:cites', undefined, 'action'],
      ['classes/test:Evidence', 'relations/test:cites', undefined, 'object-0'],
      ['external/classes/ext:Record', 'relations/test:cites', undefined, 'object-1'],
    ]);
    expect(flow.edges.some((edge) => edge.id.startsWith('relation/test:cites/'))).toBe(false);
    expect(flow.edges.find((edge) => edge.id === 'field/test:Approve/evidence')).toMatchObject({
      source: 'classes/test:Evidence', target: 'classes/test:Approve', targetHandle: 'field-evidence', data: { source: fieldSource },
    });
    expect(flow.nodes.find((node) => node.id === 'external/classes/ext:Record')?.data.kind).toBe('external');
  });

  it('uses foundation import aliases and local ancestry for Action without guessing an unrelated name', () => {
    const classes = [...graph.classes,
      { id: 'Base', fqid: 'test:Base', extends: 'foundation:Action', source: source('/spec/classes/Base') },
      { id: 'Child', fqid: 'test:Child', extends: 'test:Base', source: source('/spec/classes/Child') },
      { id: 'Action', fqid: 'test:Action', source: source('/spec/classes/Action') }];
    const flow = buildGraph(parseProjection({ ...graph, classes,
      imports: [{ id: 'ontology.foundation', version: '0.2.0', namespace: 'foundation' }] }));
    expect(flow.nodes.find((node) => node.id === 'classes/test:Child')?.data.isAction).toBe(true);
    expect(flow.nodes.find((node) => node.id === 'classes/test:Action')?.data.isAction).toBe(false);
  });

  it('recognizes inherited actions from an unloaded transitive foundation by its exact identity', () => {
    const classes = [...graph.classes,
      { id: 'Base', fqid: 'test:Base', extends: 'pkg-foundation-1234:Action', source: source('/spec/classes/Base') },
      { id: 'Child', fqid: 'test:Child', extends: 'test:Base', source: source('/spec/classes/Child') },
      { id: 'Other', fqid: 'test:Other', extends: 'pkg-unrelated-1234:Action', source: source('/spec/classes/Other') },
      { id: 'Old', fqid: 'test:Old', extends: 'pkg-foundation-old:Action', source: source('/spec/classes/Old') },
    ];
    const flow = buildGraph(parseProjection({ ...graph, classes, externalImports: [
      { id: 'ontology.foundation', version: '0.2.0', alias: 'pkg-foundation-1234' },
      { id: 'example.unrelated', version: '0.2.0', alias: 'pkg-unrelated-1234' },
      { id: 'ontology.foundation', version: '0.1.0', alias: 'pkg-foundation-old' },
    ] }));
    expect(flow.nodes.find((node) => node.id === 'classes/test:Base')?.data.isAction).toBe(true);
    expect(flow.nodes.find((node) => node.id === 'classes/test:Child')?.data.isAction).toBe(true);
    expect(flow.nodes.find((node) => node.id === 'classes/test:Other')?.data.isAction).toBe(false);
    expect(flow.nodes.find((node) => node.id === 'classes/test:Old')?.data.isAction).toBe(false);
  });

  it('disambiguates colliding port names and does not bind imported field refs in the wrong scope', () => {
    const importedSource = { ...source('/spec/classes/Imported'), id: 'example.imported' };
    const imported = { id: 'Imported', fqid: 'dep:Imported', source: importedSource, diagramOrigin: 'example.imported@1.0.0',
      fields: [{ id: 'other', type: 'ref', target: 'test:Evidence' }] };
    const otherEvidence = { id: 'Evidence', fqid: 'dep:Evidence', source: { ...importedSource, pointer: '/spec/classes/Evidence' } };
    const flow = buildGraph(parseProjection({ ...graph, classes: [...graph.classes, imported, otherEvidence],
      sources: [...graph.sources, { id: 'example.imported', version: '1.0.0', namespace: 'original', alias: 'dep', sourceDigest: digest, sourceByteDigest: digest }],
      relations: [{ ...graph.relations[0], action: 'dep:Imported', range: 'test:Evidence' }] }));
    const relation = flow.nodes.find((node) => node.id === 'relations/test:cites');
    expect(relation?.data.ports?.find((port) => port.role === 'object')?.label).toBe('object: test:Evidence');
    const field = flow.edges.find((edge) => edge.id === 'field/dep:Imported/other');
    expect(field?.source).toBe('external/scoped/dep:Imported/test:Evidence');
    expect(field?.data?.source).toEqual(importedSource);
    expect(flow.nodes.find((node) => node.id === field?.source)?.data.kind).toBe('external');
    expect(flow.nodes.find((node) => node.id === 'classes/dep:Imported')?.data.fieldTargets).toBeUndefined();
  });

  it.each(['full', 'relations'])('binds an imported field to its exact loaded target in %s view', (view) => {
    const importedSource = { ...source('/spec/classes/Imported'), id: 'example.imported' };
    const imported = { id: 'Imported', fqid: 'dep:Imported', source: importedSource, diagramOrigin: 'example.imported@1.0.0',
      fields: [{ id: 'other', type: 'ref', target: 'test:Evidence', targetType: 'test:Evidence',
        targetUri: 'ontology://example.test/1.0.0/classes/Evidence', targetSourceDigest: digest }] };
    const flow = buildGraph(parseProjection({ ...graph, view, classes: [...graph.classes, imported],
      sources: [...graph.sources, { id: 'example.imported', version: '1.0.0', namespace: 'original', alias: 'dep', sourceDigest: digest, sourceByteDigest: digest }] }));
    const edge = flow.edges.find((item) => item.id === 'field/dep:Imported/other');
    expect(edge?.source).toBe('classes/test:Evidence');
    expect(flow.nodes.find((node) => node.id === 'classes/dep:Imported')?.data.fieldTargets?.other).toBe('test:Evidence');
    expect(flow.nodes.some((node) => node.id === 'external/scoped/dep:Imported/test:Evidence')).toBe(false);
  });

  it('uses the source namespace when the target has a different composition alias', () => {
    const importedSource = { ...source('/spec/classes/Evidence'), id: 'example.imported' };
    const evidence = { id: 'Evidence', fqid: 'dep:Evidence', source: importedSource };
    const owner = { ...graph.classes[0], fields: [{ id: 'other', type: 'ref', target: 'dep:Evidence',
      targetType: 'original:Evidence', targetUri: 'ontology://example.imported/1.0.0/classes/Evidence', targetSourceDigest: digest }] };
    const flow = buildGraph(parseProjection({ ...graph, classes: [owner, ...graph.classes.slice(1), evidence],
      sources: [...graph.sources, { id: 'example.imported', version: '1.0.0', namespace: 'original', alias: 'dep', sourceDigest: digest, sourceByteDigest: digest }] }));
    expect(flow.edges.find((item) => item.id === 'field/test:Proposal/other')?.source).toBe('classes/dep:Evidence');
    expect(flow.nodes.find((node) => node.id === 'classes/test:Proposal')?.data.fieldTargets?.other).toBe('dep:Evidence');
  });

  it.each([
    ['package', { targetUri: 'ontology://example.other/1.0.0/classes/Evidence' }],
    ['version', { targetUri: 'ontology://example.test/2.0.0/classes/Evidence' }],
    ['digest', { targetSourceDigest: `sha256:${'b'.repeat(64)}` }],
    ['canonical type', { targetType: 'wrong:Evidence' }],
    ['partial metadata', { targetUri: null }],
    ['missing class', { target: 'test:Missing' }],
  ])('keeps an imported field unresolved when its %s does not match', (_, mismatch) => {
    const importedSource = { ...source('/spec/classes/Imported'), id: 'example.imported' };
    const field = { id: 'other', type: 'ref', target: 'test:Evidence', targetType: 'test:Evidence',
      targetUri: 'ontology://example.test/1.0.0/classes/Evidence', targetSourceDigest: digest, ...mismatch };
    const imported = { id: 'Imported', fqid: 'dep:Imported', source: importedSource, fields: [field] };
    const flow = buildGraph(parseProjection({ ...graph, classes: [...graph.classes, imported],
      sources: [...graph.sources, { id: 'example.imported', version: '1.0.0', namespace: 'original', alias: 'dep', sourceDigest: digest, sourceByteDigest: digest }] }));
    const edge = flow.edges.find((item) => item.id === 'field/dep:Imported/other');
    expect(edge?.source).toBe(`external/scoped/dep:Imported/${field.target}`);
    expect(flow.nodes.find((node) => node.id === 'classes/dep:Imported')?.data.fieldTargets).toBeUndefined();
  });

  it('keeps local field references connected after their package alias is rebased', () => {
    const importedSource = { ...source('/spec/classes/Imported'), id: 'example.imported' };
    const imported = { id: 'Imported', fqid: 'dep:Imported', source: importedSource,
      fields: [{ id: 'other', type: 'ref', target: 'dep:Evidence' }] };
    const evidence = { id: 'Evidence', fqid: 'dep:Evidence', source: { ...importedSource, pointer: '/spec/classes/Evidence' } };
    const flow = buildGraph(parseProjection({ ...graph, classes: [...graph.classes, imported, evidence],
      sources: [...graph.sources, { id: 'example.imported', version: '1.0.0', namespace: 'original', alias: 'dep', sourceDigest: digest, sourceByteDigest: digest }] }));
    expect(flow.edges.find((item) => item.id === 'field/dep:Imported/other')?.source).toBe('classes/dep:Evidence');
  });

  it('rejects invalid versions, malformed relations, and duplicate declarations', () => {
    expect(() => parseProjection({ ...graph, schemaVersion: 'unknown' })).toThrow(/schemaVersion/);
    expect(() => parseProjection({ ...graph, relations: [{ ...graph.relations[0], range: { oneOf: [] } }] })).toThrow(/range/);
    expect(() => parseProjection({ ...graph, classes: [...graph.classes, graph.classes[0]] })).toThrow(/duplicate/i);
    expect(() => parseProjection({ ...graph, classes: [{ ...graph.classes[0], source: { ...source('/spec/classes/Proposal'), sourceByteDigest: 'invalid' } }] })).toThrow(/sourceByteDigest/);
    expect(() => parseProjection({ ...graph, classes: [{ ...graph.classes[0], source: { ...source('/spec/classes/Proposal'), id: 'unloaded' } }] })).toThrow(/loaded package/);
  });
});

describe('class field sources', () => {
  const owner = graph.classes[0];
  const pointer = '/spec/classes/Proposal/fields/evidence';
  const other = { ...graph.sources[0], id: 'example.imported', namespace: 'original', alias: 'dep' };
  const field = { id: 'evidence', type: 'ref', target: 'test:Evidence' };
  const withSource = (fieldSource: unknown) => ({
    ...graph, sources: [...graph.sources, other],
    classes: [{ ...owner, fields: [{ ...field, source: fieldSource }] }, graph.classes[1]],
  });

  it.each([
    ['another loaded package', { ...source(pointer), id: other.id }],
    ['another version', { ...source(pointer), version: '2.0.0' }],
    ['another source digest', { ...source(pointer), sourceDigest: `sha256:${'b'.repeat(64)}` }],
    ['another byte digest', { ...source(pointer), sourceByteDigest: `sha256:${'b'.repeat(64)}` }],
    ['another class', source('/spec/classes/Evidence/fields/evidence')],
    ['another field', source('/spec/classes/Proposal/fields/sibling')],
    ['a malformed digest', { ...source(pointer), sourceByteDigest: 'invalid' }],
    ['an incomplete source', { pointer }],
    ['an explicit null source', null],
  ])('rejects %s on a field', (_, supplied) => {
    expect(() => parseProjection(withSource(supplied))).toThrow(/evidence/);
  });

  it('rejects a class and its field redirected together', () => {
    const input = withSource(source('/spec/classes/Evidence/fields/evidence'));
    input.classes[0].source = source('/spec/classes/Evidence');
    expect(() => parseProjection(input)).toThrow(/test:Proposal/);
  });

  it('rejects a local class and its field claiming another loaded package', () => {
    const input = withSource({ ...source(pointer), id: other.id });
    input.classes[0].source = { ...owner.source, id: other.id };
    expect(() => parseProjection(input)).toThrow(/test:Proposal/);
  });

  it('retains escaped field pointers in the original package under an import alias', () => {
    const classSource = { ...source('/spec/classes/A~0B~1C'), id: other.id };
    const fieldSource = { ...classSource, pointer: classSource.pointer + '/fields/path~1to~0field' };
    const imported = { id: 'A~B/C', fqid: 'dep:A~B/C', source: classSource,
      fields: [{ ...field, id: 'path/to~field', source: fieldSource }] };
    const flow = buildGraph(parseProjection({ ...graph, sources: [...graph.sources, other], classes: [imported] }));
    expect(flow.edges.find(edge => edge.data?.kind === 'field-ref')?.data?.source).toEqual(fieldSource);
  });
});
