import { describe, expect, it } from 'vitest';
import { canonicalJson } from '../../../src/http/canonicalJson';

describe('canonicalJson (03 §2.3)', () => {
  it('sorts keys recursively and drops whitespace', () => {
    expect(canonicalJson('{ "b": 2, "a": { "d": [3, {"z":1,"y":2}], "c": null } }')).toBe(
      '{"a":{"c":null,"d":[3,{"y":2,"z":1}]},"b":2}',
    );
  });

  it('gives key order no influence', () => {
    expect(canonicalJson('{"x":1,"y":"ü"}')).toBe(canonicalJson('{"y":"ü",  "x":1}'));
  });

  it('keeps scalars and arrays', () => {
    expect(canonicalJson(' [1, "a", true] ')).toBe('[1,"a",true]');
    expect(canonicalJson('42')).toBe('42');
  });

  it('maps an empty body to the empty string and leaves non-JSON as is', () => {
    expect(canonicalJson('')).toBe('');
    expect(canonicalJson('  ')).toBe('');
    expect(canonicalJson('not json {')).toBe('not json {');
  });
});
