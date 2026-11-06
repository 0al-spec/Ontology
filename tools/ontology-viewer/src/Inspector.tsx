import type { Selection } from './selection';
import type { ViewerNode } from './graph';

export function Inspector({ selection, filtered = false, classReferences, onSelectClass }: {
  selection: Selection | null; filtered?: boolean; classReferences: ReadonlyMap<string, ViewerNode>; onSelectClass: (fqid: string) => void;
}) {
  if (!selection) return <aside className="inspector empty-inspector">
    <div className="inspector-icon">◈</div>
    <h2>Explore the model</h2>
    <p>Select a node or a relation to inspect its definition and source.</p>
  </aside>;
  const data = selection.data;
  const label = selection.type === 'node' ? selection.data.label : selection.data.semanticId;
  const kind = selection.type === 'node' && selection.data.isAction ? 'Action' : data.kind === 'relation' ? 'Relationship' : data.kind;
  const record = data.record;
  const description = record && typeof record.description === 'string' ? record.description : '';
  const action = data.kind === 'relation' && typeof record?.action === 'string' ? record.action : '';
  const reference = (fqid: string, text = fqid) => classReferences.has(fqid)
    ? <button type="button" className="inspector-reference" title={fqid} onClick={() => onSelectClass(fqid)}>{text}</button>
    : <span title={fqid}>{text}</span>;
  const range = record?.range;
  const choices = typeof range === 'object' && range !== null && 'oneOf' in range && Array.isArray(range.oneOf)
    ? range.oneOf.filter((item): item is string => typeof item === 'string') : [];
  const fields = selection.type === 'node' && selection.id.startsWith('classes/') && Array.isArray(record?.fields)
    ? record.fields.filter((field): field is { id: string; type: string; target: string } =>
      typeof field === 'object' && field !== null && typeof field.id === 'string' && field.type === 'ref' && typeof field.target === 'string') : [];
  return <aside className="inspector" aria-label="Inspector">
    <div className="section-label">INSPECTOR <span className="kind-pill">{kind}</span></div>
    <h2>{label}</h2>
    {filtered && <p className="notice" role="status">This selection is outside the active filters.</p>}
    {selection.type === 'node' && selection.data.kind === 'external' && <p className="notice">
      This is an unloaded reference{selection.id.startsWith('external/classes/') ? ' (class)' : selection.id.startsWith('external/protocols/') ? ' (protocol)' : ''}
      {selection.data.origin ? ` from ${selection.data.origin}` : ''}. Its declaration has not been loaded.
    </p>}
    {description && <p>{description}</p>}
    {data.kind === 'relation' && record && <dl>
      {typeof record.domain === 'string' && <><dt>Subject</dt><dd>{record.domain}</dd></>}
      {action && <><dt>Action</dt><dd>{reference(action)}</dd></>}
      {typeof range === 'string' ? <><dt>Object</dt><dd>{range}</dd></> : choices.length > 0 && <>
        <dt>Object (oneOf)</dt><dd>{choices.join(' | ')}</dd>
      </>}
    </dl>}
    {selection.type === 'edge' && record && data.kind === 'field-ref' && <dl>
      {typeof record.id === 'string' && <><dt>Field</dt><dd>{record.id}</dd></>}
      {typeof record.target === 'string' && <><dt>Target</dt><dd>{record.target}</dd></>}
      {typeof record.type === 'string' && <><dt>Type</dt><dd>{record.type}</dd></>}
    </dl>}
    {fields.length > 0 && <dl><dt>Fields</dt>{fields.map((field) => <dd key={field.id}><code>
      {selection.type === 'node' && selection.data.fieldTargets?.[field.id]
        ? reference(selection.data.fieldTargets[field.id], `${field.id}: Ref<${field.target.split(':').pop() || field.target}>`)
        : <span title={field.target}>{`${field.id}: Ref<${field.target.split(':').pop() || field.target}>`}</span>}
    </code></dd>)}</dl>}
    {data.source && <section className="source-box">
      <div className="section-label">SOURCE</div>
      <strong>{data.source.id} <span>@ {data.source.version}</span></strong>
      <code>{data.source.pointer}</code>
      <small title={data.source.sourceByteDigest}>File SHA-256 · {data.source.sourceByteDigest.slice(7, 19)}…</small>
    </section>}
    {record && <details><summary>Declaration data</summary><pre>{JSON.stringify(record, null, 2)}</pre></details>}
  </aside>;
}
