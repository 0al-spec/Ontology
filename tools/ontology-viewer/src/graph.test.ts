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

  it('rejects invalid versions, malformed relations, and duplicate declarations', () => {
    expect(() => parseProjection({ ...graph, schemaVersion: 'unknown' })).toThrow(/schemaVersion/);
    expect(() => parseProjection({ ...graph, relations: [{ ...graph.relations[0], range: { oneOf: [] } }] })).toThrow(/range/);
    expect(() => parseProjection({ ...graph, classes: [...graph.classes, graph.classes[0]] })).toThrow(/duplicate/i);
    expect(() => parseProjection({ ...graph, classes: [{ ...graph.classes[0], source: { ...source('/spec/classes/Proposal'), sourceByteDigest: 'invalid' } }] })).toThrow(/sourceByteDigest/);
    expect(() => parseProjection({ ...graph, classes: [{ ...graph.classes[0], source: { ...source('/spec/classes/Proposal'), id: 'unloaded' } }] })).toThrow(/loaded package/);
  });
});
