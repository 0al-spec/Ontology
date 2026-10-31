/** HTML textareas normalize CRLF and CR. Preserve untouched raw bytes across edits. */
export function displayText(raw: string): string {
  return raw.replace(/\r\n|\r/g, '\n');
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

/** Apply one textarea change as a minimal raw-text replacement. */
export function applyDisplayEdit(raw: string, nextDisplay: string): string {
  const previous = displayText(raw);
  if (previous === nextDisplay) return raw;
  let start = 0;
  while (start < previous.length && start < nextDisplay.length && previous[start] === nextDisplay[start]) start++;
  let end = previous.length;
  let nextEnd = nextDisplay.length;
  while (end > start && nextEnd > start && previous[end - 1] === nextDisplay[nextEnd - 1]) { end--; nextEnd--; }
  const rawStart = rawOffset(raw, start);
  const rawEnd = rawOffset(raw, end);
  const removedBreaks = raw.slice(rawStart, rawEnd).match(/\r\n|\r|\n/g) || [];
  const neighbor = raw.slice(0, rawStart).match(/\r\n|\r|\n/g)?.at(-1)
    || raw.slice(rawEnd).match(/\r\n|\r|\n/)?.[0] || '\n';
  let index = 0;
  const inserted = nextDisplay.slice(start, nextEnd).replace(/\n/g, () => removedBreaks[index++] || neighbor);
  return raw.slice(0, rawStart) + inserted + raw.slice(rawEnd);
}
