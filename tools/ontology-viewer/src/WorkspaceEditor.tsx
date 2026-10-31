import { useEffect, useRef, useState } from 'react';
import { applyDisplayEdit, displayText } from './sourceText';

export interface WorkspaceSnapshot {
  source: { name: string; content: string; digest: string };
  diagnostics: { severity?: string; code?: string; path?: string; message?: string }[];
  toolError: string | null;
  graph: unknown | null;
  graphError: string | null;
  graphKey: string;
}
type Draft = { raw: string; baseline: string; digest: string; conflict: boolean };

export function WorkspaceEditor({ token, onSnapshot }: { token: string; onSnapshot: (snapshot: WorkspaceSnapshot) => void }) {
  const [draft, setDraft] = useState<Draft | null>(null);
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const draftRef = useRef<Draft | null>(null);
  const callback = useRef(onSnapshot);
  const refresh = useRef<() => Promise<void>>(async () => {});
  callback.current = onSnapshot;
  function update(next: Draft) { draftRef.current = next; setDraft(next); }

  useEffect(() => {
    let stopped = false;
    let busy = false;
    async function pull() {
      if (busy) return;
      busy = true;
      try {
        const response = await fetch('/api/session', { headers: { 'x-ontology-token': token }, cache: 'no-store' });
        const value = await response.json();
        if (!response.ok) throw new Error(value.error || 'Workspace unavailable');
        if (stopped) return;
        const next = value as WorkspaceSnapshot;
        const current = draftRef.current;
        if (!current || current.raw === current.baseline) {
          update({ raw: next.source.content, baseline: next.source.content, digest: next.source.digest, conflict: false });
        } else if (next.source.digest !== current.digest && !current.conflict) {
          update({ ...current, conflict: true });
        }
        setSnapshot(next);
        setError('');
        callback.current(next);
      } catch (reason) {
        if (!stopped) setError(reason instanceof Error ? reason.message : 'Workspace unavailable');
      } finally { busy = false; }
    }
    refresh.current = pull;
    void pull();
    const timer = window.setInterval(() => void pull(), 1200);
    return () => { stopped = true; window.clearInterval(timer); };
  }, [token]);

  useEffect(() => {
    const protectDraft = (event: BeforeUnloadEvent) => {
      const current = draftRef.current;
      if (current && current.raw !== current.baseline) event.preventDefault();
    };
    window.addEventListener('beforeunload', protectDraft);
    return () => window.removeEventListener('beforeunload', protectDraft);
  }, []);

  async function save() {
    const sent = draftRef.current;
    if (!sent || sent.conflict || sent.raw === sent.baseline) return;
    setSaving(true);
    try {
      const response = await fetch('/api/save', { method: 'POST', headers: { 'content-type': 'application/json', 'x-ontology-token': token },
        body: JSON.stringify({ expectedDigest: sent.digest, content: sent.raw }) });
      const result = await response.json();
      if (response.status === 409) {
        const current = draftRef.current;
        if (current) update({ ...current, conflict: true });
        throw new Error('The file changed on disk. Your draft is still here.');
      }
      if (!response.ok) throw new Error(result.error || 'Save failed');
      const current = draftRef.current;
      if (current && current.digest === sent.digest) update({ raw: current.raw, baseline: sent.raw, digest: result.digest, conflict: false });
      setError('');
      await refresh.current();
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Save failed'); }
    finally { setSaving(false); }
  }

  function reload() {
    if (!snapshot || !draft) return;
    if (draft.raw !== draft.baseline && !window.confirm('Replace your unsaved draft with the file on disk?')) return;
    update({ raw: snapshot.source.content, baseline: snapshot.source.content, digest: snapshot.source.digest, conflict: false });
    setError('');
  }

  const dirty = Boolean(draft && draft.raw !== draft.baseline);
  return <section className="workspace-editor" aria-label="YAML editor">
    <div className="editor-bar">
      <div><strong>Source YAML</strong> <span>{snapshot?.source.name || 'Connecting…'}</span></div>
      <span className={`editor-status ${draft?.conflict ? 'conflict' : ''}`}>
        {!draft ? 'Connecting…' : draft.conflict ? 'Changed on disk' : dirty ? 'Unsaved changes' : 'Saved'}
      </span>
      <button onClick={reload} disabled={!snapshot || !draft}>Reload file</button>
      <button className="primary-button" onClick={() => void save()} disabled={!dirty || draft?.conflict || saving}>Save YAML</button>
    </div>
    {error && <div className="editor-error" role="alert">{error}</div>}
    {draft?.conflict && <div className="editor-error">The source changed externally. Your unsaved draft is preserved; reload only after copying or reconciling it.</div>}
    {snapshot?.toolError && <div className="editor-error">{snapshot.toolError}</div>}
    {snapshot && !snapshot.graph && <div className="editor-error">Graph is stale. {snapshot.graphError || snapshot.toolError || 'Fix the source to refresh it.'}</div>}
    {snapshot?.diagnostics.map((item, index) => <div className="diagnostic" key={`${item.path}-${index}`}>
      {item.severity || 'info'} · {item.code || 'diagnostic'} · {item.path || 'package'} · {item.message || ''}
    </div>)}
    <textarea aria-label="Ontology YAML source" spellCheck={false} value={draft ? displayText(draft.raw) : ''} disabled={!draft}
      onChange={(event) => { const current = draftRef.current; if (current) update({ ...current, raw: applyDisplayEdit(current.raw, event.target.value) }); }} />
  </section>;
}
