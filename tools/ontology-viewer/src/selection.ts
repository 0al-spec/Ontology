import type { ViewerEdgeData, ViewerNodeData } from './graph';

export type Selection = { type: 'node'; data: ViewerNodeData } |
  { type: 'edge'; id: string; source: string; target: string; data: ViewerEdgeData };
