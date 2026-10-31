import type { ViewerEdge, ViewerNode } from './graph';
import type { Projection, SourceLocation } from './projection';

export const unattributedPackage = '@unattributed';

export function packageIdentity(source: Pick<SourceLocation, 'id' | 'version'>): string {
  return `${source.id}@${source.version}`;
}

/** State nodes inherit their machine source; their display origin is not a package. */
export function nodePackage(node: ViewerNode): string {
  if (node.data.source) return packageIdentity(node.data.source);
  if (node.data.kind === 'external' && node.data.origin && /^.+@[^@]+$/.test(node.data.origin)) return node.data.origin;
  return unattributedPackage;
}

export function edgePackage(edge: ViewerEdge): string {
  return edge.data?.source ? packageIdentity(edge.data.source) : unattributedPackage;
}

export type PackageOption = { key: string; label: string; loaded: boolean; nodeCount: number; edgeCount: number };

/** Discover identities and counts from the entire graph, never the current selection. */
export function graphPackages(
  graph: { nodes: ViewerNode[]; edges: ViewerEdge[] }, projection: Pick<Projection, 'sources' | 'imports' | 'id' | 'version'>,
): PackageOption[] {
  const entries = new Map<string, PackageOption>();
  const ensure = (key: string, loaded = false) => {
    let entry = entries.get(key);
    if (!entry) {
      entry = { key, label: key === unattributedPackage ? 'Unattributed references' : key, loaded, nodeCount: 0, edgeCount: 0 };
      entries.set(key, entry);
    } else if (loaded) entry.loaded = true;
    return entry;
  };
  for (const [records, loaded] of [[projection.sources, true], [projection.imports, false]] as const) {
    for (const record of records) {
      if (typeof record.id === 'string' && record.id && typeof record.version === 'string' && record.version) {
        ensure(packageIdentity({ id: record.id, version: record.version }), loaded);
      }
    }
  }
  for (const node of graph.nodes) ensure(nodePackage(node)).nodeCount++;
  for (const edge of graph.edges) ensure(edgePackage(edge)).edgeCount++;
  const root = packageIdentity(projection);
  return [...entries.values()].sort((a, b) => {
    if (a.key === root) return b.key === root ? 0 : -1;
    if (b.key === root) return 1;
    return a.label.localeCompare(b.label);
  });
}
