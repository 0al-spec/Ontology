import { describe, expect, it } from 'vitest';
import { applyDisplayEdit, displayText, findHistoryEdit } from './sourceText';

describe('exact YAML source editing', () => {
  it('keeps BOM, comments and mixed line endings around a changed value', () => {
    const original = '\ufeff# heading\r\nname: Old # keep\rnext: value\n# trailing\r\n';
    const display = displayText(original);
    const edited = display.replace('Old', 'New');
    const start = display.indexOf('Old');
    expect(applyDisplayEdit(original, edited, { start, end: start + 3, inputType: 'insertText' }))
      .toEqual({ raw: '\ufeff# heading\r\nname: New # keep\rnext: value\n# trailing\r\n', ambiguous: false });
  });

  it('preserves existing terminators and uses the neighboring style for new lines', () => {
    const original = '# header\r\na: one\r\nb: two\r\n';
    const edited = displayText(original).replace('a: one\n', 'a: one\nc: three\n');
    expect(applyDisplayEdit(original, edited)).toEqual({ raw: '# header\r\na: one\r\nc: three\r\nb: two\r\n', ambiguous: false });
    expect(applyDisplayEdit(original, displayText(original))).toEqual({ raw: original, ambiguous: false });
  });

  it('uses the selected or caret position to disambiguate adjacent mixed line endings', () => {
    const raw = 'A\r\n\nB';
    const next = 'A\nB';
    expect(applyDisplayEdit(raw, next, { start: 1, end: 2, inputType: 'deleteContentBackward' }))
      .toEqual({ raw: 'A\nB', ambiguous: false });
    expect(applyDisplayEdit(raw, next, { start: 2, end: 2, inputType: 'deleteContentBackward' }))
      .toEqual({ raw: 'A\nB', ambiguous: false });
    expect(applyDisplayEdit(raw, next, { start: 1, end: 1, inputType: 'deleteContentForward' }))
      .toEqual({ raw: 'A\nB', ambiguous: false });
    expect(applyDisplayEdit(raw, next, { start: 2, end: 3, inputType: 'deleteContentBackward' }))
      .toEqual({ raw: 'A\r\nB', ambiguous: false });
    expect(applyDisplayEdit(raw, next).ambiguous).toBe(true);
  });

  it('never silently guesses an unreported edit range in a mixed-ending file', () => {
    const result = applyDisplayEdit('aa\n\r', '\n');
    expect(result.ambiguous).toBe(true);
    expect(displayText(result.raw)).toBe('\n');
  });

  it('avoids joining separate CR and LF boundaries when editing', () => {
    const inserted = applyDisplayEdit('a\ra\n', '\n\n', { start: 0, end: 3, inputType: 'insertText' });
    expect(displayText(inserted.raw)).toBe('\n\n');
    expect(inserted.ambiguous).toBe(false);
    const joined = applyDisplayEdit('A\rX\nB', 'A\n\nB', { start: 2, end: 3, inputType: 'deleteContentBackward' });
    expect(displayText(joined.raw)).toBe('A\n\nB');
    expect(joined.ambiguous).toBe(true);
  });

  it('does not silently choose between equal-looking undo states with different raw bytes', () => {
    const entries = ['A\r\nB', 'A\nB', 'A\nC'].map((raw) => ({ raw, ambiguous: false }));
    expect(findHistoryEdit(entries, 2, -1, 'A\nB')).toEqual({ index: 1, result: { raw: 'A\nB', ambiguous: true } });
    expect(findHistoryEdit(entries, 1, -1, 'A\nB')).toEqual({ index: 0, result: { raw: 'A\r\nB', ambiguous: false } });
    expect(findHistoryEdit(entries, 2, -1, 'not present')).toBeNull();
  });
});
