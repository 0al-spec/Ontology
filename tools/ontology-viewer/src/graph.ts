import dagre from '@dagrejs/dagre';
import { MarkerType, type Edge, type Node } from '@xyflow/react';
import type { Declaration, JsonObject, Projection, SourceLocation } from './projection';
import { importNamespace } from './projection';

export { parseProjection } from './projection';

export type NodeKind = 'class' | 'imported' | 'protocol' | 'policy' | 'machine' | 'state' | 'external' | 'relation';
export type NodePort = { id: string; role: 'subject' | 'action' | 'object' | 'field'; label: string; title: string };
export type ViewerNodeData = {
  label: string;
  kind: NodeKind;
  record?: JsonObject;
  source?: SourceLocation;
  origin?: string;
  isAction?: boolean;
  ports?: NodePort[];
  fieldTargets?: Record<string, string>;
};
export type ViewerEdgeData = { semanticId: string; kind: string; record: JsonObject; source?: SourceLocation };
export type ViewerNode = Node<ViewerNodeData>;
export type ViewerEdge = Edge<ViewerEdgeData>;

const width = 250;
const height = (node: ViewerNode) => 76 + (node.data.ports?.length || 0) * 34;

function strings(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string' && item.length > 0) : [];
}

function string(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function objects(value: unknown): JsonObject[] {
  return Array.isArray(value) ? value.filter((item): item is JsonObject => typeof item === 'object' && item !== null && !Array.isArray(item)) : [];
}

function layoutWithPortOrder(layout: dagre.graphlib.Graph, edges: ViewerEdge[]) {
  // Role edges are emitted in declaration order: subject, action, then object alternatives.
  const inputs = new Map<string, string[]>();
  const uses = new Map<string, number>();
  for (const edge of edges) {
    if (edge.data?.kind !== 'relation' || !edge.targetHandle) continue;
    const peers = inputs.get(edge.target);
    if (peers) peers.push(edge.source);
    else inputs.set(edge.target, [edge.source]);
    uses.set(edge.source, (uses.get(edge.source) || 0) + 1);
  }

  dagre.layout(layout, { customOrder(graph, defaultOrder) {
    defaultOrder(graph, {});
    for (const peers of inputs.values()) {
      if (peers.some((id) => uses.get(id) !== 1)) continue;
      // Dagre computes the order within each rank before it places cards of different heights.
      const labels = peers.map((id) => graph.node(id) as dagre.Node<{ order: number }>);
      const slots = labels.map((label) => label.order).sort((a, b) => a - b);
      if (labels.some((label) => label.rank !== labels[0].rank)) continue;
      if (slots.some((slot, index) => slot !== slots[0] + index)) continue;
      // Only permute an uninterrupted block of inputs to one relationship.
      labels.forEach((label, index) => { label.order = slots[index]; });
    }
  } });
}

/** Project semantic declarations to presentation elements without changing the source graph. */
export function buildGraph(projection: Projection): { nodes: ViewerNode[]; edges: ViewerEdge[] } {
  const nodes: ViewerNode[] = [];
  const edges: ViewerEdge[] = [];
  const refs = new Set<string>();
  for (const record of projection.classes) {
    refs.add(record.fqid);
    for (const field of objects(record.fields)) if (string(field.target)) refs.add(string(field.target));
  }
  for (const relation of projection.relations) {
    refs.add(relation.domain);
    if (string(relation.action)) refs.add(string(relation.action));
    for (const target of typeof relation.range === 'string' ? [relation.range] : relation.range.oneOf) refs.add(target);
  }
  const shortNames = new Map<string, number>();
  for (const ref of refs) { const name = ref.split(':').pop() || ref; shortNames.set(name, (shortNames.get(name) || 0) + 1); }
  const displayRef = (ref: string) => { const name = ref.split(':').pop() || ref; return shortNames.get(name) === 1 ? name : ref; };
  const known = new Map<string, ViewerNode>();
  const actions = new Set(projection.relations.map((item) => string(item.action)).filter(Boolean));
  const foundation = [...projection.imports.filter((item) => item.id === 'ontology.foundation' && item.version === '0.2.0').map(importNamespace),
    ...projection.sources.filter((item) => item.id === 'ontology.foundation' && item.version === '0.2.0').map((item) => string(item.alias)),
    ...(projection.externalImports || []).filter((item) => item.id === 'ontology.foundation' && item.version === '0.2.0').map((item) => string(item.alias))];
  const isFoundationAction = (ref: string) => foundation.some((alias) => alias && ref === `${alias}:Action`);
  let changed = true;
  while (changed) {
    changed = false;
    for (const item of projection.classes) {
      const base = string(item.extends);
      if (!actions.has(item.fqid) && (isFoundationAction(base) || actions.has(base))) {
        actions.add(item.fqid);
        changed = true;
      }
    }
  }
  const addNode = (id: string, data: ViewerNodeData) => {
    if (known.has(id)) return;
    const node: ViewerNode = { id, type: 'ontology', position: { x: 0, y: 0 }, data,
      className: `ontology-node node--${data.kind}${data.isAction ? ' node--action' : ''}` };
    known.set(id, node);
    nodes.push(node);
  };
  const nodeId = (section: string, ref: string) => `${section}/${ref}`;
  const addDeclarations = (section: string, kind: NodeKind, records: Declaration[]) => {
    for (const record of records) {
      const origin = string(record.diagramOrigin) || undefined;
      addNode(nodeId(section, record.fqid), {
        label: record.fqid, kind: kind === 'class' && origin ? 'imported' : kind, record, source: record.source, origin,
        isAction: section === 'classes' && actions.has(record.fqid),
        ports: section === 'classes' ? objects(record.fields).filter((field) => field.type === 'ref' && string(field.id) && string(field.target))
          .map((field) => ({ id: `field-${string(field.id)}`, role: 'field' as const,
            label: `${string(field.id)}: Ref<${displayRef(string(field.target))}>`, title: `${string(field.id)}: Ref<${string(field.target)}>` })) : undefined,
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
    const imported = projection.imports.find((item) => importNamespace(item) === namespace) ||
      projection.externalImports?.find((item) => item.alias === namespace);
    const origin = imported ? `${string(imported.id)}@${string(imported.version)}` : undefined;
    addNode(id, { label: ref, kind: 'external', origin });
    return id;
  };
  const edge = (id: string, source: string, target: string, label: string, data: ViewerEdgeData, options?: { sourceHandle?: string; targetHandle?: string; neutral?: boolean; role?: string }) => {
    edges.push({ id, source, target, label, data, type: 'smoothstep', className: `edge--${data.kind}`,
      sourceHandle: options?.sourceHandle, targetHandle: options?.targetHandle,
      ...(options?.role ? { className: `edge--${data.kind} edge--role-${options.role}` } : {}),
      ...(options?.role === 'object' ? { pathOptions: { stepPosition: 0.08 } } : {}),
      markerEnd: options?.neutral ? undefined : { type: MarkerType.ArrowClosed, width: 15, height: 15, color: '#90aa9b' } });
  };

  for (const relation of projection.relations) {
    const targets = typeof relation.range === 'string' ? [relation.range] : relation.range.oneOf;
    const action = string(relation.action);
    if (action) {
      const id = nodeId('relations', relation.fqid);
      addNode(id, { label: relation.fqid, kind: 'relation', record: relation, source: relation.source, ports: [
        { id: 'subject', role: 'subject', label: `subject: ${displayRef(relation.domain)}`, title: `subject: ${relation.domain}` },
        { id: 'action', role: 'action', label: `action: ${displayRef(action)}`, title: `action: ${action}` },
        ...targets.map((target, index) => ({ id: `object-${index}`, role: 'object' as const,
          label: `object${targets.length > 1 ? ' · oneOf' : ''}: ${displayRef(target)}`, title: `object: ${target}` })),
      ] });
      const data = { semanticId: relation.fqid, kind: 'relation', record: relation, source: relation.source };
      edge(`role/${relation.fqid}/subject`, reference('classes', relation.domain), id, '', data, { targetHandle: 'subject', neutral: true, role: 'subject' });
      edge(`role/${relation.fqid}/action`, reference('classes', action), id, '', data, { targetHandle: 'action', neutral: true, role: 'action' });
      targets.forEach((target, index) => edge(`role/${relation.fqid}/object/${index}`, reference('classes', target), id,
        '', data, { targetHandle: `object-${index}`, neutral: true, role: 'object' }));
      continue;
    }
    const choice = typeof relation.range === 'string' ? '' : ' · oneOf';
    targets.forEach((target, index) => edge(
      `relation/${relation.fqid}/${index}`, reference('classes', relation.domain), reference('classes', target),
      `${relation.fqid}${choice}`, { semanticId: relation.fqid, kind: 'relation', record: relation, source: relation.source },
    ));
  }

  for (const record of projection.classes) {
    const from = nodeId('classes', record.fqid);
    const ownerNode = known.get(from);
    const owner = projection.sources.find((item) => item.id === record.source.id && item.version === record.source.version);
    for (const field of record.fields ?? []) {
      if (field.type !== 'ref' || !string(field.id) || !string(field.target)) continue;
      const target = string(field.target);
      let targetNode: string;
      if (owner && owner.alias !== projection.namespace) {
        const [namespace, local] = target.split(':');
        if (namespace === owner.namespace && local) targetNode = reference('classes', `${string(owner.alias)}:${local}`);
        else {
          targetNode = `external/scoped/${record.fqid}/${target}`;
          addNode(targetNode, { label: target, kind: 'external', origin: `Unresolved in ${record.source.id}@${record.source.version}` });
        }
      } else targetNode = reference('classes', target);
      if (ownerNode && targetNode.startsWith('classes/')) {
        ownerNode.data.fieldTargets ??= {};
        ownerNode.data.fieldTargets[string(field.id)] = targetNode.slice('classes/'.length);
      }
      edge(`field/${record.fqid}/${string(field.id)}`, targetNode, from,
        '', { semanticId: `${record.fqid}.${string(field.id)}`, kind: 'field-ref', record: field, source: field.source ?? record.source },
        { targetHandle: `field-${string(field.id)}`, neutral: true, role: 'field' });
    }
    if (projection.view !== 'full') continue;
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

  if (projection.view === 'full') {
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
  layout.setGraph({ rankdir: 'LR', nodesep: 60, ranksep: 75, edgesep: 35, marginx: 28, marginy: 28 });
  for (const node of [...nodes].sort((a, b) => a.id.localeCompare(b.id))) layout.setNode(node.id, { width, height: height(node) });
  for (const item of [...edges].sort((a, b) => a.id.localeCompare(b.id))) layout.setEdge(item.source, item.target,
    { width: Math.min(180, String(item.label || '').length * 7), height: 20 }, item.id);
  layoutWithPortOrder(layout, edges);
  for (const node of nodes) {
    const position = layout.node(node.id) as { x: number; y: number };
    node.position = { x: position.x - width / 2, y: position.y - height(node) / 2 };
  }
  return { nodes, edges };
}
