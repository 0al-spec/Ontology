import type { Selection } from './selection';

export function Inspector({ selection, filtered = false }: { selection: Selection | null; filtered?: boolean }) {
  if (!selection) return <aside className="inspector empty-inspector">
    <div className="inspector-icon">◈</div>
    <h2>Explore the model</h2>
    <p>Select a node or a relation to inspect its definition and source.</p>
  </aside>;
  const data = selection.data;
  const label = selection.type === 'node' ? selection.data.label : selection.data.semanticId;
  const kind = selection.type === 'node' ? selection.data.kind : selection.data.kind;
  const record = data.record;
  const description = record && typeof record.description === 'string' ? record.description : '';
  return <aside className="inspector" aria-label="Inspector">
    <div className="section-label">INSPECTOR <span className="kind-pill">{kind}</span></div>
    <h2>{label}</h2>
    {filtered && <p className="notice" role="status">This selection is outside the active filters.</p>}
    {selection.type === 'node' && selection.data.kind === 'external' && <p className="notice">
      This is an unloaded reference{selection.id.startsWith('external/classes/') ? ' (class)' : selection.id.startsWith('external/protocols/') ? ' (protocol)' : ''}
      {selection.data.origin ? ` from ${selection.data.origin}` : ''}. Its declaration has not been loaded.
    </p>}
    {description && <p>{description}</p>}
    {selection.type === 'edge' && record && <dl>
      {typeof record.domain === 'string' && <><dt>Domain</dt><dd>{record.domain}</dd></>}
      {record.range !== undefined && <><dt>Range</dt><dd>{typeof record.range === 'string' ? record.range : JSON.stringify(record.range)}</dd></>}
    </dl>}
    {data.source && <section className="source-box">
      <div className="section-label">SOURCE</div>
      <strong>{data.source.id} <span>@ {data.source.version}</span></strong>
      <code>{data.source.pointer}</code>
      <small title={data.source.sourceByteDigest}>File SHA-256 · {data.source.sourceByteDigest.slice(7, 19)}…</small>
    </section>}
    {record && <details><summary>Declaration data</summary><pre>{JSON.stringify(record, null, 2)}</pre></details>}
  </aside>;
}
