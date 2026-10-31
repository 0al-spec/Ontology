import { describe, expect, it } from 'vitest';
import { applyDisplayEdit, displayText } from './sourceText';

describe('exact YAML source editing', () => {
  it('keeps BOM, comments and mixed line endings around a changed value', () => {
    const original = '\ufeff# heading\r\nname: Old # keep\rnext: value\n# trailing\r\n';
    const display = displayText(original);
    const edited = display.replace('Old', 'New');
    expect(applyDisplayEdit(original, edited)).toBe('\ufeff# heading\r\nname: New # keep\rnext: value\n# trailing\r\n');
  });

  it('preserves existing terminators and uses the neighboring style for new lines', () => {
    const original = '# header\r\na: one\r\nb: two\r\n';
    const edited = displayText(original).replace('a: one\n', 'a: one\nc: three\n');
    expect(applyDisplayEdit(original, edited)).toBe('# header\r\na: one\r\nc: three\r\nb: two\r\n');
    expect(applyDisplayEdit(original, displayText(original))).toBe(original);
  });
});
