import { useMemo, useRef, useState, type ChangeEvent } from 'react';
import { GraphCanvas } from './GraphCanvas';
import { Inspector } from './Inspector';
import { buildGraph, parseProjection } from './graph';
import type { Projection } from './projection';
import type { Selection } from './selection';
import './style.css';

export default function App() {
  const [projection, setProjection] = useState<Projection | null>(null);
  const [fileName, setFileName] = useState('');
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selection, setSelection] = useState<Selection | null>(null);
  // A new request is needed even when the same result is selected twice.
  const [focusNode, setFocusNode] = useState<{ id: string } | null>(null);
  const input = useRef<HTMLInputElement>(null);
  const graph = useMemo(() => projection ? buildGraph(projection) : null, [projection]);
  const matches = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query || !graph) return [];
    const nodes = graph.nodes.filter((node) => node.data.label.toLowerCase().includes(query))
      .map((node) => ({ id: node.id, label: node.data.label, kind: node.data.kind, focusNode: node.id, selection: { type: 'node', data: node.data } as Selection }));
    const seen = new Set<string>();
    const relations = graph.edges.filter((edge) => {
      const data = edge.data;
      if (!data || data.kind !== 'relation' || !data.semanticId.toLowerCase().includes(query) || seen.has(data.semanticId)) return false;
      seen.add(data.semanticId);
      return true;
    }).map((edge) => ({ id: edge.id, label: edge.data!.semanticId, kind: 'relation', focusNode: edge.source, selection: { type: 'edge', data: edge.data! } as Selection }));
    return [...nodes, ...relations].slice(0, 50);
  }, [graph, search]);

  async function openFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    try {
      const parsed = parseProjection(JSON.parse(await file.text()) as unknown);
      // Build before publishing the selection, so malformed data keeps the current view.
      buildGraph(parsed);
      setProjection(parsed);
      setFileName(file.name);
      setSelection(null);
      setFocusNode(null);
      setSearch('');
      setError('');
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Could not open graph');
    }
  }

  return <div className="app">
    <header className="topbar">
      <div className="brand-mark">◈</div>
      <div className="brand"><strong>Ontology</strong><span>GRAPH VIEWER</span></div>
      <span className="topbar-divider" />
      <span className="file-name">{fileName || 'No graph open'}</span>
      <span className="readonly-badge">READ ONLY</span>
      <button className="primary-button" onClick={() => input.current?.click()}>Open graph <span>↗</span></button>
      <input ref={input} className="file-input" type="file" accept=".json,application/json" aria-label="Open graph JSON" onChange={openFile} />
    </header>
    {error && <div className="error-bar" role="alert"><strong>Could not open graph.</strong> {error}</div>}
    {projection && graph ? <main className="workspace">
      <section className="sidebar" aria-label="Graph navigation">
        <div className="section-label">PACKAGE</div>
        <h1>{projection.id}</h1>
        <p className="package-version">{projection.version} <span>·</span> {projection.view} view</p>
        <div className="sidebar-rule" />
        <label className="search-label" htmlFor="graph-search">Search graph</label>
        <input id="graph-search" className="search" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Type a name…" />
        {search.trim() ? <div className="search-results" aria-label="Search results">
          <span className="section-label">{matches.length} MATCHES</span>
          {matches.map((match) => <button key={match.id} onClick={() => { setSelection(match.selection); setFocusNode({ id: match.focusNode }); }}>
            <span>{match.label}</span><small>{match.kind}</small>
          </button>)}
        </div> : <div className="legend">
          <div><i className="legend-class" /> Class</div><div><i className="legend-imported" /> Imported class</div>
          <div><i className="legend-other" /> Protocol / policy</div>
          <div><i className="legend-external" /> Unloaded reference</div>
          <p>Drag nodes to arrange the view. Select a line to inspect its relation.</p>
        </div>}
        <div className="sidebar-footer">{graph.nodes.length} nodes <span>·</span> {graph.edges.length} visual links</div>
      </section>
      <GraphCanvas graph={graph} search={search} focusNode={focusNode} onSelect={setSelection} />
      <Inspector selection={selection} />
    </main> : <main className="welcome">
      <div className="welcome-symbol">◈</div>
      <div className="section-label">LOCAL GRAPH WORKSPACE</div>
      <h1>Make your ontology<br /><em>visible.</em></h1>
      <p>Open a graph projection to explore its concepts, relationships and source locations.</p>
      <button className="primary-button large" onClick={() => input.current?.click()}>Open graph JSON <span>↗</span></button>
      <code>ontologyviz --format json --out diagrams</code>
    </main>}
  </div>;
}
