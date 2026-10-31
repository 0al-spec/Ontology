import { describe, expect, it } from 'vitest';
import { defaultFilters, graphVisibility, nodeFilterType, nodeOrigin } from './filters';
import type { ViewerEdge, ViewerNode } from './graph';

const digest = `sha256:${'a'.repeat(64)}`;
const node = (id: string, kind: ViewerNode['data']['kind'], sourceId?: string): ViewerNode => ({
  id, position: { x: 100, y: 200 }, data: { kind, label: id, source: sourceId ? {
    id: sourceId, version: '1.0.0', sourceDigest: digest, sourceByteDigest: digest, pointer: '/spec/classes/X',
  } : undefined },
});
const edge = (id: string, source: string, target: string, kind: string): ViewerEdge => ({
  id, source, target, data: { kind, semanticId: id, record: {} },
});

describe('graph visibility', () => {
  it('classifies type independently from source origin', () => {
    const local = node('classes/x:Local', 'class', 'example.root');
    const imported = node('classes/y:Imported', 'imported', 'example.import');
    const unloaded = node('external/protocols/y:Protocol', 'external');
    expect([local, imported, unloaded].map(nodeFilterType)).toEqual(['class', 'class', 'protocol']);
    expect([local, imported, unloaded].map((item) => nodeOrigin(item, 'example.root')))
      .toEqual(['local', 'imported', 'unresolved']);
    expect(nodeFilterType(node('external/policies/y:Policy', 'external'))).toBe('policy');
    expect(nodeFilterType(node('external/stateMachines/y:Machine', 'external'))).toBe('machine');
  });

  it('filters edges by kind and endpoints without changing positions or graph data', () => {
    const graph = {
      nodes: [node('a', 'class', 'example.root'), node('b', 'protocol', 'example.root'), node('c', 'imported', 'example.import')],
      edges: [edge('relation', 'a', 'c', 'relation'), edge('conformance', 'a', 'b', 'implements')],
    };
    const original = JSON.stringify(graph);
    const filters = defaultFilters();
    filters.nodeTypes.protocol = false;
    filters.edgeKinds.relation = false;
    const active = graphVisibility(graph, filters, 'example.root');
    expect([...active.nodeIds]).toEqual(['a', 'c']);
    expect([...active.edgeIds]).toEqual([]);
    expect(JSON.stringify(graph)).toBe(original);
    filters.mode = 'dim';
    expect([...graphVisibility(graph, filters, 'example.root').nodeIds]).toEqual(['a', 'c']);
  });

  it('can disable imports or unresolved references while keeping local nodes', () => {
    const graph = { nodes: [node('local', 'class', 'example.root'), node('imported', 'imported', 'example.import'),
      node('external/classes/y:Missing', 'external')], edges: [] };
    const filters = defaultFilters();
    filters.origins.imported = false;
    filters.origins.unresolved = false;
    expect([...graphVisibility(graph, filters, 'example.root').nodeIds]).toEqual(['local']);
  });
});
