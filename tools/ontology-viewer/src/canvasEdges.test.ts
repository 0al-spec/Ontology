import { expect, it } from 'vitest';
import { styleCanvasEdges } from './canvasEdges';
import type { ViewerEdge } from './graph';

it('assigns stable lanes only to wires sharing both endpoints and ports', () => {
  const edge = (id: string, targetHandle = 'object'): ViewerEdge => ({ id, source: 'a', target: 'b', targetHandle });
  const edges = [edge('C'), edge('A'), edge('B'), edge('other-port', 'subject')];
  const expected = [{ lane: 1 }, { lane: -1 }, { lane: 0 }];
  for (const type of ['rect', 'curve'] as const) {
    const styled = styleCanvasEdges(edges, type);
    expect(styled.slice(0, 3)).toMatchObject(expected.map(lane => ({ type: 'parallel', pathOptions: { ...lane, lineType: type } })));
    expect(styled[3].type).toBe(type === 'rect' ? 'smoothstep' : 'default');
    expect(edges.every(edge => edge.type === undefined)).toBe(true);
  }
});

it('routes a self-loop outside its card even without a parallel wire', () => {
  const edges = styleCanvasEdges([{ id: 'self', source: 'a', target: 'a' }], 'curve');
  expect(edges[0]).toMatchObject({ type: 'parallel', pathOptions: { index: 0, lane: 0, lineType: 'curve' } });
});
