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

export function GraphCanvas({ graph, search, focusNode, onSelect }: {
  graph: { nodes: ViewerNode[]; edges: ViewerEdge[] };
  search: string;
  focusNode: string | null;
  onSelect: (selection: Selection) => void;
}) {
  const [nodes, setNodes, onNodesChange] = useNodesState(graph.nodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(graph.edges);
  const instance = useRef<ReactFlowInstance<ViewerNode, ViewerEdge> | null>(null);
  useEffect(() => { setNodes(graph.nodes); setEdges(graph.edges); }, [graph, setNodes, setEdges]);
  useEffect(() => {
    const node = focusNode ? instance.current?.getNode(focusNode) : undefined;
    if (node) void instance.current?.setCenter(node.position.x + 110, node.position.y + 38, { zoom: 1, duration: 300 });
  }, [focusNode]);
  const shownNodes = useMemo<ViewerNode[]>(() => {
    const query = search.trim().toLowerCase();
    return nodes.map((node) => ({
      ...node,
      className: `${node.className || ''}${query && node.data.label.toLowerCase().includes(query) ? ' search-match' : ''}`,
    }));
  }, [nodes, search]);
  const onNodeClick: NodeMouseHandler<ViewerNode> = (_, node) => onSelect({ type: 'node', data: node.data });
  const onEdgeClick: EdgeMouseHandler<ViewerEdge> = (_, edge) => {
    if (edge.data) onSelect({ type: 'edge', data: edge.data });
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
