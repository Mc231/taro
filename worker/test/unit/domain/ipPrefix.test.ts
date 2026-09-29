import fc from 'fast-check';
import { describe, expect, it } from 'vitest';
import { ipPrefix } from '../../../src/domain/ipPrefix';

describe('ipPrefix (03 §2.4, RC65)', () => {
  it.each([
    ['203.0.113.77', '203.0.113.0/24'],
    [' 10.1.2.3 ', '10.1.2.0/24'],
    ['0.0.0.0', '0.0.0.0/24'],
    ['255.255.255.255', '255.255.255.0/24'],
  ])('IPv4 %s → /24 %s', (ip, prefix) => {
    expect(ipPrefix(ip)).toBe(prefix);
  });

  it.each([
    ['2001:db8:85a3:8d3:1319:8a2e:370:7348', '2001:db8:85a3:8d3::/64'],
    ['2001:0DB8:0000:0001:0000:0000:0000:0001', '2001:db8:0:1::/64'],
    ['2001:db8::1', '2001:db8:0:0::/64'],
    ['2001:db8:1:2::', '2001:db8:1:2::/64'],
    ['::1', '0:0:0:0::/64'],
    ['::', '0:0:0:0::/64'],
    ['fe80::1%eth0', 'fe80:0:0:0::/64'],
    ['[2001:db8:a:b::5]', '2001:db8:a:b::/64'],
    ['64:ff9b::192.0.2.33', '64:ff9b:0:0::/64'],
  ])('IPv6 %s → /64 %s', (ip, prefix) => {
    expect(ipPrefix(ip)).toBe(prefix);
  });

  it('keeps two subscribers of one /64 together and different /64s apart', () => {
    expect(ipPrefix('2a02:1810:4d02:3a00::1')).toBe(ipPrefix('2a02:1810:4d02:3a00:ffff::9'));
    expect(ipPrefix('2a02:1810:4d02:3a00::1')).not.toBe(ipPrefix('2a02:1810:4d02:3a01::1'));
  });

  it('treats IPv4-mapped IPv6 as IPv4', () => {
    expect(ipPrefix('::ffff:198.51.100.7')).toBe('198.51.100.0/24');
    expect(ipPrefix('::ffff:c633:6407')).toBe('198.51.100.0/24');
  });

  it.each([
    undefined,
    '',
    'not-an-ip',
    '256.1.1.1',
    '1.2.3',
    '1.2.3.4.5',
    '01.2.3.x',
    '2001:db8::1::2',
    '1:2:3:4:5:6:7',
    '1:2:3:4:5:6:7:8:9',
    '1:2:3:4:5:6:7::8',
    '2001:db8::zzzz',
    '::ffff:300.1.1.1',
    '12345::1',
  ])('returns undefined for %j', (ip) => {
    expect(ipPrefix(ip)).toBeUndefined();
  });

  it('maps every IPv4 address in a /24 to the same prefix', () => {
    fc.assert(
      fc.property(fc.ipV4(), (ip) => {
        const parts = ip.split('.');
        const sibling = [...parts.slice(0, 3), '1'].join('.');
        expect(ipPrefix(ip)).toBe(ipPrefix(sibling));
      }),
    );
  });

  it('accepts every generated IPv6 address', () => {
    fc.assert(
      fc.property(fc.ipV6(), (ip) => {
        expect(ipPrefix(ip)).toMatch(/(\/64|\/24)$/);
      }),
    );
  });
});
