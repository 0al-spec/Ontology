import type { ViewerEdgeData, ViewerNodeData } from './graph';

export type Selection = { type: 'node'; id: string; data: ViewerNodeData } |
  { type: 'edge'; id: string; source: string; target: string; data: ViewerEdgeData };
