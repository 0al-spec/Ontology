import dagre from '@dagrejs/dagre';
import { MarkerType, type Edge, type Node } from '@xyflow/react';
import type { Declaration, JsonObject, Projection, SourceLocation } from './projection';

export { parseProjection } from './projection';

export type NodeKind = 'class' | 'imported' | 'protocol' | 'policy' | 'machine' | 'state' | 'external';
export type ViewerNodeData = {
  label: string;
  kind: NodeKind;
  record?: JsonObject;
  source?: SourceLocation;
  origin?: string;
};
export type ViewerEdgeData = { semanticId: string; kind: string; record: JsonObject; source?: SourceLocation };
export type ViewerNode = Node<ViewerNodeData>;
export type ViewerEdge = Edge<ViewerEdgeData>;

const width = 220;
const height = 76;

function strings(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string' && item.length > 0) : [];
}

function string(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function objects(value: unknown): JsonObject[] {
  return Array.isArray(value) ? value.filter((item): item is JsonObject => typeof item === 'object' && item !== null && !Array.isArray(item)) : [];
}

/** Project semantic declarations to presentation elements without changing the source graph. */
export function buildGraph(projection: Projection): { nodes: ViewerNode[]; edges: ViewerEdge[] } {
  const nodes: ViewerNode[] = [];
  const edges: ViewerEdge[] = [];
  const known = new Set<string>();
  const addNode = (id: string, data: ViewerNodeData) => {
    if (known.has(id)) return;
    known.add(id);
    nodes.push({ id, type: 'ontology', position: { x: 0, y: 0 }, data, className: `ontology-node node--${data.kind}` });
  };
  const nodeId = (section: string, ref: string) => `${section}/${ref}`;
  const addDeclarations = (section: string, kind: NodeKind, records: Declaration[]) => {
    for (const record of records) {
      const origin = string(record.diagramOrigin) || undefined;
      addNode(nodeId(section, record.fqid), {
        label: record.fqid, kind: kind === 'class' && origin ? 'imported' : kind, record, source: record.source, origin,
      });
    }
  };
  addDeclarations('classes', 'class', projection.classes);
  addDeclarations('protocols', 'protocol', projection.protocols);
  addDeclarations('policies', 'policy', projection.policies);
  addDeclarations('stateMachines', 'machine', projection.stateMachines);

  const reference = (section: string, ref: string): string => {
    const loaded = nodeId(section, ref);
    if (known.has(loaded)) return loaded;
    const id = `external/${loaded}`;
    const namespace = ref.split(':', 1)[0];
    const imported = projection.imports.find((item) => item.namespace === namespace);
    const origin = imported ? `${string(imported.id)}@${string(imported.version)}` : undefined;
    addNode(id, { label: ref, kind: 'external', origin });
    return id;
  };
  const edge = (id: string, source: string, target: string, label: string, data: ViewerEdgeData) => {
    edges.push({ id, source, target, label, data, type: 'smoothstep', className: `edge--${data.kind}`,
      markerEnd: { type: MarkerType.ArrowClosed, width: 15, height: 15, color: '#90aa9b' } });
  };

  for (const relation of projection.relations) {
    const targets = typeof relation.range === 'string' ? [relation.range] : relation.range.oneOf;
    const choice = typeof relation.range === 'string' ? '' : ' · oneOf';
    targets.forEach((target, index) => edge(
      `relation/${relation.fqid}/${index}`, reference('classes', relation.domain), reference('classes', target),
      `${relation.fqid}${choice}`, { semanticId: relation.fqid, kind: 'relation', record: relation, source: relation.source },
    ));
  }

  if (projection.view === 'full') {
    for (const record of projection.classes) {
      const from = nodeId('classes', record.fqid);
      const base = string(record.extends);
      if (base) edge(`extends/${record.fqid}`, from, reference('classes', base), 'extends',
        { semanticId: record.fqid, kind: 'extends', record, source: record.source });
      strings(record.implements).forEach((ref, index) => edge(`implements/${record.fqid}/${index}`, from,
        reference('protocols', ref), 'implements', { semanticId: record.fqid, kind: 'implements', record, source: record.source }));
      const lifecycle = string(record.lifecycle);
      if (lifecycle) {
        const ref = lifecycle.includes(':') ? lifecycle : `${record.fqid.split(':', 1)[0]}:${lifecycle}`;
        edge(`lifecycle/${record.fqid}`, from, reference('stateMachines', ref), 'lifecycle',
          { semanticId: record.fqid, kind: 'lifecycle', record, source: record.source });
      }
    }
    for (const record of projection.policies) {
      const from = nodeId('policies', record.fqid);
      const base = string(record.extends);
      if (base) edge(`policy-extends/${record.fqid}`, from, reference('policies', base), 'extends',
        { semanticId: record.fqid, kind: 'extends', record, source: record.source });
      strings(record.appliesTo).forEach((ref, index) => edge(`applies/${record.fqid}/${index}`, from,
        reference('classes', ref), 'appliesTo', { semanticId: record.fqid, kind: 'appliesTo', record, source: record.source }));
    }
    for (const machine of projection.stateMachines) {
      const stateId = (name: string) => `stateMachines/${machine.fqid}/states/${name}`;
      for (const state of strings(machine.states)) {
        addNode(stateId(state), { label: state, kind: 'state', record: machine, source: machine.source, origin: machine.fqid });
        edge(`contains/${machine.fqid}/${state}`, nodeId('stateMachines', machine.fqid), stateId(state), 'contains',
          { semanticId: machine.fqid, kind: 'contains', record: machine, source: machine.source });
      }
      objects(machine.transitions).forEach((transition, index) => {
        const from = stateId(string(transition.from));
        const to = stateId(string(transition.to));
        if (!known.has(from) || !known.has(to)) return;
        const label = [string(transition.command), string(transition.event)].filter(Boolean).join(' · ');
        edge(`transition/${machine.fqid}/${index}`, from, to, label || 'transition',
          { semanticId: machine.fqid, kind: 'transition', record: transition, source: machine.source });
      });
    }
  }

  const layout = new dagre.graphlib.Graph({ multigraph: true });
  layout.setDefaultEdgeLabel(() => ({}));
  layout.setGraph({ rankdir: 'LR', nodesep: 42, ranksep: 110, marginx: 28, marginy: 28 });
  for (const node of [...nodes].sort((a, b) => a.id.localeCompare(b.id))) layout.setNode(node.id, { width, height });
  for (const item of [...edges].sort((a, b) => a.id.localeCompare(b.id))) layout.setEdge(item.source, item.target, {}, item.id);
  dagre.layout(layout);
  for (const node of nodes) {
    const position = layout.node(node.id) as { x: number; y: number };
    node.position = { x: position.x - width / 2, y: position.y - height / 2 };
  }
  return { nodes, edges };
}
