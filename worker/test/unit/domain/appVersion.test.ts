import { describe, expect, it } from 'vitest';
import { compareAppVersions, parseAppVersion } from '../../../src/domain/appVersion';

function cmp(a: string, b: string): number {
  const pa = parseAppVersion(a);
  const pb = parseAppVersion(b);
  if (pa === undefined || pb === undefined) {
    throw new Error('unparsable');
  }
  return Math.sign(compareAppVersions(pa, pb));
}

describe('parseAppVersion', () => {
  it('parses X.Y.Z and X.Y.Z+B', () => {
    expect(parseAppVersion('1.2.0')).toEqual({ major: 1, minor: 2, patch: 0 });
    expect(parseAppVersion(' 1.2.0+14 ')).toEqual({ major: 1, minor: 2, patch: 0, build: 14 });
  });

  it.each(['', '1.2', '1.2.3.4', 'v1.2.3', '1.2.3+', '1.2.3-beta', 'a.b.c'])(
    'rejects %j',
    (text) => {
      expect(parseAppVersion(text)).toBeUndefined();
    },
  );
});

describe('compareAppVersions', () => {
  it.each([
    ['1.0.0', '1.0.0', 0],
    ['1.0.1', '1.0.0', 1],
    ['1.1.0', '1.0.9', 1],
    ['2.0.0', '1.99.99', 1],
    ['0.9.9', '1.0.0', -1],
    ['1.10.0', '1.9.0', 1],
    ['1.2.0+14', '1.2.0', 0],
    ['1.2.0', '1.2.0+14', 0],
    ['1.2.0+14', '1.2.0+15', -1],
    ['1.2.0+16', '1.2.0+15', 1],
  ])('%s vs %s → %i', (a, b, expected) => {
    expect(cmp(a, b)).toBe(expected);
  });
});
