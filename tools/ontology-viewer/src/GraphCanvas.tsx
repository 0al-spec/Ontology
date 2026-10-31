import { useEffect, useMemo, useRef } from 'react';
import {
  Background, Controls, Handle, MiniMap, Position, ReactFlow, useEdgesState, useNodesState,
  type EdgeMouseHandler, type NodeMouseHandler, type NodeProps, type ReactFlowInstance,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import type { ViewerEdge, ViewerNode } from './graph';
import type { Selection } from './selection';

function OntologyNode({ data }: NodeProps<ViewerNode>) {
  return <>
    <Handle type="target" position={Position.Left} isConnectable={false} />
    <span className="node-kind">{data.kind === 'external' ? 'External reference' : data.kind}</span>
    <strong>{data.label}</strong>
    {data.origin && <small>{data.origin}</small>}
    <Handle type="source" position={Position.Right} isConnectable={false} />
  </>;
}

const nodeTypes = { ontology: OntologyNode };

export function GraphCanvas({ graph, identity, search, focusNode, onSelect }: {
  graph: { nodes: ViewerNode[]; edges: ViewerEdge[] };
  identity: string;
  search: string;
  focusNode: { id: string } | null;
  onSelect: (selection: Selection) => void;
}) {
  const [nodes, setNodes, onNodesChange] = useNodesState(graph.nodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(graph.edges);
  const instance = useRef<ReactFlowInstance<ViewerNode, ViewerEdge> | null>(null);
  const previousIdentity = useRef(identity);
  useEffect(() => {
    const samePackage = previousIdentity.current === identity;
    previousIdentity.current = identity;
    setNodes((current) => {
      const previous = new Map(current.map((node) => [node.id, node]));
      return graph.nodes.map((node) => {
        const old = samePackage ? previous.get(node.id) : undefined;
        return old ? { ...node, position: old.position, selected: old.selected, dragging: old.dragging } : node;
      });
    });
    setEdges((current) => {
      const previous = new Map(current.map((edge) => [edge.id, edge]));
      return graph.edges.map((edge) => ({ ...edge, selected: samePackage ? previous.get(edge.id)?.selected : edge.selected }));
    });
  }, [graph, identity, setNodes, setEdges]);
  useEffect(() => {
    const node = focusNode ? instance.current?.getNode(focusNode.id) : undefined;
    if (node) void instance.current?.setCenter(node.position.x + 110, node.position.y + 38, { zoom: 1, duration: 300 });
  }, [focusNode]);
  const shownNodes = useMemo<ViewerNode[]>(() => {
    const query = search.trim().toLowerCase();
    return nodes.map((node) => ({
      ...node,
      className: `${node.className || ''}${query && node.data.label.toLowerCase().includes(query) ? ' search-match' : ''}`,
    }));
  }, [nodes, search]);
  const onNodeClick: NodeMouseHandler<ViewerNode> = (_, node) => onSelect({ type: 'node', id: node.id, data: node.data });
  const onEdgeClick: EdgeMouseHandler<ViewerEdge> = (_, edge) => {
    if (edge.data) onSelect({ type: 'edge', id: edge.id, source: edge.source, target: edge.target, data: edge.data });
  };
  return <div className="canvas" aria-label="Ontology graph">
    <ReactFlow
      nodes={shownNodes} edges={edges} nodeTypes={nodeTypes} onNodesChange={onNodesChange} onEdgesChange={onEdgesChange}
      onInit={(flow) => { instance.current = flow; }} onNodeClick={onNodeClick} onEdgeClick={onEdgeClick}
      nodesConnectable={false} deleteKeyCode={null}
      fitView minZoom={0.08} maxZoom={2}
    >
      <Background gap={24} color="#dbe5e1" />
      <Controls showInteractive={false} />
      <MiniMap pannable zoomable nodeColor={(node) => node.data.kind === 'external' ? '#b9c4bf' : '#71a98d'} />
    </ReactFlow>
  </div>;
}
