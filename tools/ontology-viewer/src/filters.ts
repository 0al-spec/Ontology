import type { ViewerEdge, ViewerNode } from './graph';

export const nodeTypeOptions = [
  ['class', 'Classes'], ['protocol', 'Protocols'], ['policy', 'Policies'],
  ['machine', 'State machines'], ['state', 'States'],
] as const;
export const originOptions = [
  ['local', 'Local'], ['imported', 'Imported'], ['unresolved', 'Unresolved'],
] as const;
export const edgeKindOptions = [
  ['relation', 'Ontology relations'], ['extends', 'Inheritance'], ['implements', 'Conformance'],
  ['appliesTo', 'Policy application'], ['lifecycle', 'Lifecycle'], ['contains', 'Containment'],
  ['transition', 'Transitions'],
] as const;

export type NodeFilterType = typeof nodeTypeOptions[number][0];
export type OriginFilter = typeof originOptions[number][0];
export type EdgeFilterKind = typeof edgeKindOptions[number][0];
export type FilterMode = 'hide' | 'dim';
export type GraphFilters = {
  mode: FilterMode;
  nodeTypes: Record<NodeFilterType, boolean>;
  origins: Record<OriginFilter, boolean>;
  edgeKinds: Record<EdgeFilterKind, boolean>;
};

function allEnabled<T extends string>(options: readonly (readonly [T, string])[]): Record<T, boolean> {
  return Object.fromEntries(options.map(([key]) => [key, true])) as Record<T, boolean>;
}

export function defaultFilters(): GraphFilters {
  return { mode: 'hide', nodeTypes: allEnabled(nodeTypeOptions), origins: allEnabled(originOptions), edgeKinds: allEnabled(edgeKindOptions) };
}

/** An unloaded placeholder still has an expected declaration type in its ID. */
export function nodeFilterType(node: ViewerNode): NodeFilterType {
  if (node.data.kind === 'imported') return 'class';
  if (node.data.kind !== 'external') return node.data.kind;
  const section = node.id.split('/')[1];
  if (section === 'protocols') return 'protocol';
  if (section === 'policies') return 'policy';
  if (section === 'stateMachines') return 'machine';
  return 'class';
}

export function nodeOrigin(node: ViewerNode, packageId: string): OriginFilter {
  if (node.data.kind === 'external') return 'unresolved';
  if (node.data.kind === 'imported' || (node.data.source && node.data.source.id !== packageId)) return 'imported';
  return 'local';
}

export type GraphVisibility = { nodeIds: ReadonlySet<string>; edgeIds: ReadonlySet<string> };

/** Classify the full graph without mutating its nodes, edges or layout. */
export function graphVisibility(
  graph: { nodes: ViewerNode[]; edges: ViewerEdge[] }, filters: GraphFilters, packageId: string,
): GraphVisibility {
  const nodeIds = new Set(graph.nodes.filter((node) =>
    filters.nodeTypes[nodeFilterType(node)] && filters.origins[nodeOrigin(node, packageId)],
  ).map((node) => node.id));
  const edgeIds = new Set(graph.edges.filter((edge) => {
    const kind = edge.data?.kind as EdgeFilterKind | undefined;
    const enabled = !kind || !(kind in filters.edgeKinds) || filters.edgeKinds[kind];
    return enabled && nodeIds.has(edge.source) && nodeIds.has(edge.target);
  }).map((edge) => edge.id));
  return { nodeIds, edgeIds };
}

export type FilterCounts = {
  nodeTypes: Record<NodeFilterType, number>;
  origins: Record<OriginFilter, number>;
  edgeKinds: Record<EdgeFilterKind, number>;
};

/** Counts describe the full loaded canvas, independently of enabled filters. */
export function graphFilterCounts(graph: { nodes: ViewerNode[]; edges: ViewerEdge[] }, packageId: string): FilterCounts {
  const zeros = <T extends string>(options: readonly (readonly [T, string])[]) =>
    Object.fromEntries(options.map(([key]) => [key, 0])) as Record<T, number>;
  const counts: FilterCounts = { nodeTypes: zeros(nodeTypeOptions), origins: zeros(originOptions), edgeKinds: zeros(edgeKindOptions) };
  for (const node of graph.nodes) {
    counts.nodeTypes[nodeFilterType(node)]++;
    counts.origins[nodeOrigin(node, packageId)]++;
  }
  for (const edge of graph.edges) {
    const kind = edge.data?.kind as EdgeFilterKind | undefined;
    if (kind && kind in counts.edgeKinds) counts.edgeKinds[kind]++;
  }
  return counts;
}
