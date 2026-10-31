import { useEffect, useRef, useState } from 'react';
import { applyDisplayEdit, displayText, findHistoryEdit, type EditHint, type EditResult } from './sourceText';

export interface WorkspaceSnapshot {
  source: { name: string; content: string; digest: string };
  diagnostics: { severity?: string; code?: string; path?: string; message?: string }[];
  toolError: string | null;
  graph: unknown | null;
  graphError: string | null;
  graphKey: string;
}
type Draft = { raw: string; baseline: string; digest: string; conflict: boolean; ambiguous: boolean };

export function WorkspaceEditor({ token, onSnapshot }: { token: string; onSnapshot: (snapshot: WorkspaceSnapshot) => void }) {
  const [draft, setDraft] = useState<Draft | null>(null);
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const [error, setError] = useState('');
  const [checking, setChecking] = useState(false);
  const [inputBlocked, setInputBlocked] = useState(false);
  const [saving, setSaving] = useState(false);
  const draftRef = useRef<Draft | null>(null);
  const textarea = useRef<HTMLTextAreaElement>(null);
  const beforeInput = useRef<{ previous: string; hint: EditHint } | null>(null);
  const history = useRef<{ entries: EditResult[]; index: number }>({ entries: [], index: -1 });
  const callback = useRef(onSnapshot);
  const refresh = useRef<() => Promise<void>>(async () => {});
  callback.current = onSnapshot;
  function update(next: Draft) { draftRef.current = next; setDraft(next); }
  function resetHistory(raw: string) { history.current = { entries: [{ raw, ambiguous: false }], index: 0 }; }

  function edit(current: Draft, next: string, hint?: EditHint) {
    if (displayText(current.raw) === next) return;
    const previous = history.current;
    const direction = hint?.inputType === 'historyUndo' ? -1 : hint?.inputType === 'historyRedo' ? 1 : 0;
    if (direction) {
      const found = findHistoryEdit(previous.entries, previous.index, direction, next);
      if (found) {
        history.current = { ...previous, index: found.index };
        update({ ...current, ...found.result });
        return;
      }
    }
    const result = applyDisplayEdit(current.raw, next, hint);
    result.ambiguous ||= current.ambiguous;
    const entries = [...previous.entries.slice(0, previous.index + 1), result].slice(-100);
    history.current = { entries, index: entries.length - 1 };
    update({ ...current, ...result });
  }

  useEffect(() => {
    const element = textarea.current;
    if (!element) return;
    const capture = (event: Event) => {
      const current = draftRef.current;
      if (!current || displayText(current.raw) !== element.value) { beforeInput.current = null; return; }
      beforeInput.current = { previous: element.value, hint: { start: element.selectionStart, end: element.selectionEnd,
        inputType: (event as InputEvent).inputType || '' } };
    };
    element.addEventListener('beforeinput', capture);
    return () => element.removeEventListener('beforeinput', capture);
  }, []);

  useEffect(() => {
    let stopped = false;
    let busy = false;
    async function pull() {
      if (busy) return;
      busy = true;
      try {
        const response = await fetch('/api/session', { headers: { 'x-ontology-token': token }, cache: 'no-store' });
        const value = await response.json();
        if (stopped) return;
        if (response.status === 409 && value.retryable) { setChecking(true); setError(''); return; }
        if (!response.ok) throw new Error(value.error || 'Workspace unavailable');
        const next = value as WorkspaceSnapshot;
        const current = draftRef.current;
        if (!current || (current.raw === current.baseline && !current.ambiguous)) {
          if (!current || current.raw !== next.source.content) resetHistory(next.source.content);
          update({ raw: next.source.content, baseline: next.source.content, digest: next.source.digest, conflict: false, ambiguous: false });
        } else if (next.source.digest !== current.digest && !current.conflict) {
          update({ ...current, conflict: true });
        }
        setSnapshot(next);
        setChecking(false);
        setInputBlocked(false);
        setError('');
        callback.current(next);
      } catch (reason) {
        if (!stopped) { setChecking(false); setInputBlocked(true); setError(reason instanceof Error ? reason.message : 'Workspace unavailable'); }
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
      if (current && (current.raw !== current.baseline || current.ambiguous)) event.preventDefault();
    };
    window.addEventListener('beforeunload', protectDraft);
    return () => window.removeEventListener('beforeunload', protectDraft);
  }, []);

  async function save() {
    const sent = draftRef.current;
    if (!sent || sent.conflict || sent.ambiguous || inputBlocked || sent.raw === sent.baseline) return;
    setSaving(true);
    try {
      const response = await fetch('/api/save', { method: 'POST', headers: { 'content-type': 'application/json', 'x-ontology-token': token },
        body: JSON.stringify({ expectedDigest: sent.digest, content: sent.raw }) });
      const result = await response.json();
      if (response.status === 409) {
        const current = draftRef.current;
        if (result.code === 'input_changed') setInputBlocked(true);
        else if (current) update({ ...current, conflict: true });
        throw new Error(result.error || 'The file changed on disk. Your draft is still here.');
      }
      if (!response.ok) throw new Error(result.error || 'Save failed');
      const current = draftRef.current;
      if (current && current.digest === sent.digest) update({ ...current, baseline: sent.raw, digest: result.digest, conflict: false });
      setError('');
      await refresh.current();
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Save failed'); }
    finally { setSaving(false); }
  }

  function reload() {
    if (!snapshot || !draft) return;
    if ((draft.raw !== draft.baseline || draft.ambiguous) && !window.confirm('Replace your unsaved draft with the file on disk?')) return;
    resetHistory(snapshot.source.content);
    update({ raw: snapshot.source.content, baseline: snapshot.source.content, digest: snapshot.source.digest, conflict: false, ambiguous: false });
    setError('');
  }

  const dirty = Boolean(draft && (draft.raw !== draft.baseline || draft.ambiguous));
  return <section className="workspace-editor" aria-label="YAML editor">
    <div className="editor-bar">
      <div><strong>Source YAML</strong> <span>{snapshot?.source.name || 'Connecting…'}</span></div>
      <span className={`editor-status ${draft?.conflict ? 'conflict' : ''}`}>
        {!draft ? 'Connecting…' : draft.conflict ? 'Changed on disk' : draft.ambiguous ? 'Line endings need review' : dirty ? 'Unsaved changes' : 'Saved'}
      </span>
      <button onClick={reload} disabled={!snapshot || !draft}>Reload file</button>
      <button className="primary-button" onClick={() => void save()} disabled={!dirty || draft?.conflict || draft?.ambiguous || inputBlocked || saving}>Save YAML</button>
    </div>
    {error && <div className="editor-error" role="alert">{error}</div>}
    {inputBlocked && <div className="editor-error">The graph may be stale; the draft is preserved until the selected inputs are available.</div>}
    {checking && <div className="diagnostic" role="status">Source is changing; waiting for a stable snapshot. The graph may be stale.</div>}
    {draft?.conflict && <div className="editor-error">The source changed externally. Your unsaved draft is preserved; reload only after copying or reconciling it.</div>}
    {draft?.ambiguous && <div className="editor-error" role="alert">The exact line endings for this edit are ambiguous. Undo it or copy the draft before reloading; saving is disabled.</div>}
    {snapshot?.toolError && <div className="editor-error">{snapshot.toolError}</div>}
    {snapshot && !snapshot.graph && <div className="editor-error">Graph is stale. {snapshot.graphError || snapshot.toolError || 'Fix the source to refresh it.'}</div>}
    {snapshot?.diagnostics.map((item, index) => <div className="diagnostic" key={`${item.path}-${index}`}>
      {item.severity || 'info'} · {item.code || 'diagnostic'} · {item.path || 'package'} · {item.message || ''}
    </div>)}
    <textarea ref={textarea} aria-label="Ontology YAML source" spellCheck={false} value={draft ? displayText(draft.raw) : ''} disabled={!draft}
      onChange={(event) => {
        const current = draftRef.current;
        const captured = beforeInput.current;
        beforeInput.current = null;
        if (current) edit(current, event.target.value, captured?.previous === displayText(current.raw) ? captured.hint : undefined);
      }} />
  </section>;
}
