import { describe, expect, it } from 'vitest';
import { defaultFilters, graphVisibility } from './filters';
import { edgePackage, graphPackages, nodePackage, packageIdentity, unattributedPackage } from './packages';
import type { ViewerEdge, ViewerNode } from './graph';

const source = (id: string, version = '1.0.0') => ({ id, version, sourceDigest: 'sha256:a', sourceByteDigest: 'sha256:a', pointer: '/spec/classes/X' });
const node = (id: string, owner?: string, version?: string): ViewerNode => ({
  id, position: { x: 12, y: 34 }, data: { label: id, kind: 'class', source: owner ? source(owner, version) : undefined },
});
const edge = (id: string, owner: string, from = 'a', to = 'b'): ViewerEdge => ({
  id, source: from, target: to, data: { semanticId: id, kind: 'relation', record: {}, source: source(owner) },
});

describe('package filtering', () => {
  it('uses source identity for states and aliases, and distinguishes versions', () => {
    const state = node('alias:review/states/draft', 'example.dep');
    state.data.kind = 'state'; state.data.origin = 'alias:review';
    expect(nodePackage(state)).toBe('example.dep@1.0.0');
    expect(nodePackage(node('other:SameClass', 'example.dep'))).toBe(nodePackage(state));
    expect(nodePackage(node('alias:SameClass', 'example.dep', '2.0.0'))).not.toBe(nodePackage(state));
    const filters = defaultFilters();
    filters.packages['example.dep@1.0.0'] = false;
    expect([...graphVisibility({ nodes: [state, node('v2', 'example.dep', '2.0.0')], edges: [] }, filters, 'root').nodeIds]).toEqual(['v2']);
  });

  it('keeps declared unloaded references distinct from unattributed nodes', () => {
    const external = node('external/classes/f:Value');
    external.data.kind = 'external'; external.data.origin = 'foundation@0.1.0';
    const unknown = node('external/classes/unknown:Value'); unknown.data.kind = 'external';
    expect(nodePackage(external)).toBe('foundation@0.1.0');
    expect(nodePackage(unknown)).toBe(unattributedPackage);
    const unknownEdge: ViewerEdge = { id: 'unattributed-link', source: external.id, target: unknown.id };
    expect(edgePackage(unknownEdge)).toBe(unattributedPackage);
    const options = graphPackages({ nodes: [external, unknown], edges: [unknownEdge] }, {
      id: 'root', version: '1.0.0', sources: [{ id: 'root', version: '1.0.0' }],
      imports: [{ id: 'foundation', version: '0.1.0' }, { id: 'unused', version: '1.0.0' }],
    });
    expect(options.find((item) => item.key === 'foundation@0.1.0')).toMatchObject({ loaded: false, nodeCount: 1 });
    expect(options.find((item) => item.key === 'unused@1.0.0')).toMatchObject({ loaded: false, nodeCount: 0 });
    expect(options.find((item) => item.key === unattributedPackage)).toMatchObject({ nodeCount: 1, edgeCount: 1 });
    const filters = defaultFilters();
    filters.packages[unattributedPackage] = false;
    expect([...graphVisibility({ nodes: [external, unknown], edges: [unknownEdge] }, filters, 'root').nodeIds]).toEqual([external.id]);
  });

  it('filters an edge by its owner even when both endpoints belong to enabled packages', () => {
    const graph = { nodes: [node('a', 'root'), node('b', 'dep')], edges: [edge('third-party-rule', 'rules')] };
    const before = JSON.stringify(graph), filters = defaultFilters();
    filters.packages[packageIdentity(source('rules'))] = false;
    const visible = graphVisibility(graph, filters, 'root');
    expect([...visible.nodeIds]).toEqual(['a', 'b']);
    expect(visible.edgeIds.size).toBe(0);
    expect(edgePackage(graph.edges[0])).toBe('rules@1.0.0');
    expect(JSON.stringify(graph)).toBe(before);
    filters.packages = { 'dep@1.0.0': false };
    expect(graphVisibility(graph, filters, 'root').edgeIds.size).toBe(0);
  });

  it('retains fixed counts and defaults newly appearing identities to enabled', () => {
    const graph = { nodes: [node('a', 'root'), node('b', 'dep')], edges: [edge('rule', 'root')] };
    const projection = { id: 'root', version: '1.0.0', sources: [source('root'), source('dep')], imports: [] };
    const counts = graphPackages(graph, projection), filters = defaultFilters();
    filters.packages['dep@1.0.0'] = false;
    graphVisibility(graph, filters, 'root');
    expect(graphPackages(graph, projection)).toEqual(counts);
    const updated = { ...graph, nodes: [...graph.nodes, node('new', 'new-package')] };
    expect([...graphVisibility(updated, filters, 'root').nodeIds]).toEqual(['a', 'new']);
    filters.origins.imported = false;
    expect([...graphVisibility(updated, filters, 'root').nodeIds]).toEqual(['a']);
    expect(graphPackages(graph, projection).find((item) => item.key === 'root@1.0.0')).toMatchObject({ nodeCount: 1, edgeCount: 1, loaded: true });
  });
});
