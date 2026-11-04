import { BaseEdge, useReactFlow, type EdgeProps } from '@xyflow/react';
import type { ViewerEdge } from './graph';

export type LineType = 'rect' | 'curve';
type ParallelRoute = { lineType: LineType; index: number; lane: number };

export function styleCanvasEdges(edges: ViewerEdge[], lineType: LineType): ViewerEdge[] {
  const groups = new Map<string, string[]>();
  for (const edge of edges) {
    const ports = JSON.stringify([edge.source, edge.sourceHandle, edge.target, edge.targetHandle]);
    const group = groups.get(ports);
    if (group) group.push(edge.id);
    else groups.set(ports, [edge.id]);
  }
  const routes = new Map<string, ParallelRoute>();
  for (const ids of groups.values()) {
    if (ids.length < 2) continue;
    ids.sort().forEach((id, index) => routes.set(id, { lineType, index, lane: index - (ids.length - 1) / 2 }));
  }
  return edges.map(edge => {
    const route = routes.get(edge.id) ?? (edge.source === edge.target ? { lineType, index: 0, lane: 0 } : undefined);
    if (route) return { ...edge, type: 'parallel', pathOptions: route };
    return { ...edge, type: lineType === 'rect' ? 'smoothstep' : 'default' };
  });
}

// The Viewer connects right-hand output ports to left-hand input ports.
function ParallelEdge({ source, target, sourceX, sourceY, targetX, targetY, pathOptions,
  label, markerStart, markerEnd, style, interactionWidth }: EdgeProps) {
  const { getInternalNode } = useReactFlow();
  const { lineType, index, lane } = pathOptions as ParallelRoute;
  const forward = targetX > sourceX;
  const lead = forward ? Math.min((targetX - sourceX) / 4, 24 + index * 8) : 32 + index * 8;
  const out = sourceX + lead, into = targetX - lead;
  const midX = (sourceX + targetX) / 2;
  // Backward wires and self-loops pass above both cards.
  const midY = forward ? (sourceY + targetY) / 2 + lane * 44
    : Math.min(getInternalNode(source)?.internals.positionAbsolute.y ?? sourceY,
      getInternalNode(target)?.internals.positionAbsolute.y ?? targetY) - 32 - index * 44;
  const start = `M ${sourceX} ${sourceY}`;
  let path: string;
  if (lineType === 'rect') {
    path = `${start} H ${out} V ${midY} H ${into} V ${targetY} H ${targetX}`;
  } else if (forward) {
    path = `${start} C ${out} ${sourceY} ${out} ${midY} ${midX} ${midY} S ${into} ${targetY} ${targetX} ${targetY}`;
  } else {
    path = `${start} C ${out} ${sourceY} ${out} ${midY} ${sourceX} ${midY} H ${targetX} C ${into} ${midY} ${into} ${targetY} ${targetX} ${targetY}`;
  }
  return <BaseEdge path={path} label={label} labelX={midX} labelY={midY}
    markerStart={markerStart} markerEnd={markerEnd} style={style} interactionWidth={interactionWidth} />;
}

export const canvasEdgeTypes = { parallel: ParallelEdge };
