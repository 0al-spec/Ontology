/** HTML textareas normalize CRLF and CR. Preserve untouched raw bytes across edits. */
export function displayText(raw: string): string {
  return raw.replace(/\r\n|\r/g, '\n');
}

export type EditHint = { start: number; end: number; inputType: string };
export type EditResult = { raw: string; ambiguous: boolean };
type EditRange = { start: number; end: number; nextEnd: number };

/** Native undo does not identify which equal-looking raw revision it restored. */
export function findHistoryEdit(entries: EditResult[], from: number, direction: -1 | 1, display: string): { index: number; result: EditResult } | null {
  const matches: number[] = [];
  for (let index = from + direction; index >= 0 && index < entries.length; index += direction) {
    if (displayText(entries[index].raw) === display) matches.push(index);
  }
  if (!matches.length) return null;
  const index = matches[0];
  const result = entries[index];
  return { index, result: { ...result, ambiguous: result.ambiguous || matches.some((candidate) => entries[candidate].raw !== result.raw) } };
}

function rawOffset(raw: string, displayOffset: number): number {
  let display = 0;
  let index = 0;
  while (index < raw.length && display < displayOffset) {
    if (raw[index] === '\r' && raw[index + 1] === '\n') index += 2;
    else index += 1;
    display += 1;
  }
  return index;
}

function replaceRange(raw: string, next: string, range: EditRange): EditResult {
  const rawStart = rawOffset(raw, range.start);
  const rawEnd = rawOffset(raw, range.end);
  const removedBreaks = raw.slice(rawStart, rawEnd).match(/\r\n|\r|\n/g) || [];
  const neighbor = raw.slice(0, rawStart).match(/\r\n|\r|\n/g)?.at(-1)
    || raw.slice(rawEnd).match(/\r\n|\r|\n/)?.[0] || '\n';
  let index = 0;
  const changed = next.slice(range.start, range.nextEnd);
  const inserted = changed.replace(/\n/g, () => removedBreaks[index++] || neighbor);
  const prefix = raw.slice(0, rawStart);
  const suffix = raw.slice(rawEnd);
  const result = prefix + inserted + suffix;
  if (displayText(result) === next) return { raw: result, ambiguous: false };
  // An inserted CR adjacent to an untouched LF can accidentally form CRLF.
  // A CRLF within the edited portion avoids combining at either boundary.
  const safeInsertion = prefix + changed.replace(/\n/g, '\r\n') + suffix;
  if (displayText(safeInsertion) === next) return { raw: safeInsertion, ambiguous: false };
  // Deleting text can join an untouched CR and LF. Keep the intended display,
  // but require review instead of silently rewriting either line ending.
  return { raw: next.replace(/\n/g, '\r\n'), ambiguous: true };
}

function hintedRange(previous: string, next: string, hint: EditHint): EditRange | null {
  let { start, end } = hint;
  if (!Number.isInteger(start) || !Number.isInteger(end) || start < 0 || end < start || end > previous.length) return null;
  if (hint.inputType.startsWith('history')) return null;
  if (start === end && hint.inputType.startsWith('delete') && hint.inputType.endsWith('Backward')) {
    const suffix = previous.slice(end);
    start = next.length - suffix.length;
    if (start < 0 || start > end || previous.slice(0, start) !== next.slice(0, start) || next.slice(start) !== suffix) return null;
    return { start, end, nextEnd: start };
  }
  if (start === end && hint.inputType.startsWith('delete') && hint.inputType.endsWith('Forward')) {
    const prefix = previous.slice(0, start);
    end = previous.length - (next.length - start);
    if (end < start || end > previous.length || next.slice(0, start) !== prefix || next.slice(start) !== previous.slice(end)) return null;
    return { start, end, nextEnd: start };
  }
  const nextEnd = next.length - (previous.length - end);
  if (nextEnd < start || previous.slice(0, start) !== next.slice(0, start) || previous.slice(end) !== next.slice(nextEnd)) return null;
  return { start, end, nextEnd };
}

function minimalRange(previous: string, next: string, preferPrefix: boolean): EditRange {
  let start = 0;
  let end = previous.length;
  let nextEnd = next.length;
  if (preferPrefix) {
    while (start < end && start < nextEnd && previous[start] === next[start]) start++;
    while (end > start && nextEnd > start && previous[end - 1] === next[nextEnd - 1]) { end--; nextEnd--; }
  } else {
    while (end > 0 && nextEnd > 0 && previous[end - 1] === next[nextEnd - 1]) { end--; nextEnd--; }
    while (start < end && start < nextEnd && previous[start] === next[start]) start++;
  }
  return { start, end, nextEnd };
}

/** Use the browser's edit range when available; never silently guess a conflicting raw representation. */
export function applyDisplayEdit(raw: string, nextDisplay: string, hint?: EditHint): EditResult {
  const previous = displayText(raw);
  if (previous === nextDisplay) return { raw, ambiguous: false };
  const exact = hint && hintedRange(previous, nextDisplay, hint);
  if (exact) return replaceRange(raw, nextDisplay, exact);
  const left = replaceRange(raw, nextDisplay, minimalRange(previous, nextDisplay, true));
  const right = replaceRange(raw, nextDisplay, minimalRange(previous, nextDisplay, false));
  // Without a verified range, a replacement can cover identical-looking lines
  // well beyond either minimal diff. Mixed terminators make that unknowable.
  const mixedEndings = new Set(raw.match(/\r\n|\r|\n/g) || []).size > 1;
  return { raw: left.raw, ambiguous: mixedEndings || left.ambiguous || right.ambiguous || left.raw !== right.raw };
}
