import { describe, expect, it } from 'vitest';
import { buildGraph, parseProjection } from './graph';

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
    expect(flow.nodes.find((node) => node.id === field?.source)?.data.kind).toBe('external');
    expect(flow.nodes.find((node) => node.id === 'classes/dep:Imported')?.data.fieldTargets).toBeUndefined();
  });

  it('rejects invalid versions, malformed relations, and duplicate declarations', () => {
    expect(() => parseProjection({ ...graph, schemaVersion: 'unknown' })).toThrow(/schemaVersion/);
    expect(() => parseProjection({ ...graph, relations: [{ ...graph.relations[0], range: { oneOf: [] } }] })).toThrow(/range/);
    expect(() => parseProjection({ ...graph, classes: [...graph.classes, graph.classes[0]] })).toThrow(/duplicate/i);
    expect(() => parseProjection({ ...graph, classes: [{ ...graph.classes[0], source: { ...source('/spec/classes/Proposal'), sourceByteDigest: 'invalid' } }] })).toThrow(/sourceByteDigest/);
    expect(() => parseProjection({ ...graph, classes: [{ ...graph.classes[0], source: { ...source('/spec/classes/Proposal'), id: 'unloaded' } }] })).toThrow(/loaded package/);
  });
});
