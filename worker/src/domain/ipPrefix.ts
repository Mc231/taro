/**
 * IP → limiter prefix (03 §2.4, RC65): IPv4 /24, IPv6 /64 (one household or
 * one mobile subscriber). IPv4-mapped IPv6 addresses count as IPv4. The raw
 * IP is never stored; only `HMAC(IP_HASH_KEY, prefix)` is used as a key.
 * Returns undefined for anything that is not a valid address.
 */
export function ipPrefix(ip: string | undefined): string | undefined {
  if (ip === undefined) {
    return undefined;
  }
  const trimmed = ip.trim();
  const v4 = parseIpv4(trimmed);
  if (v4 !== undefined) {
    return `${v4.slice(0, 3).join('.')}.0/24`;
  }
  const v6 = parseIpv6(trimmed);
  if (v6 === undefined) {
    return undefined;
  }
  if (isIpv4Mapped(v6)) {
    const [hi, lo] = [v6[6] ?? 0, v6[7] ?? 0];
    return `${String(hi >> 8)}.${String(hi & 0xff)}.${String(lo >> 8)}.0/24`;
  }
  return `${v6
    .slice(0, 4)
    .map((group) => group.toString(16))
    .join(':')}::/64`;
}

function parseIpv4(text: string): number[] | undefined {
  const parts = text.split('.');
  if (parts.length !== 4) {
    return undefined;
  }
  const octets: number[] = [];
  for (const part of parts) {
    if (!/^\d{1,3}$/.test(part)) {
      return undefined;
    }
    const value = Number(part);
    if (value > 255) {
      return undefined;
    }
    octets.push(value);
  }
  return octets;
}

function parseGroups(text: string): number[] | undefined {
  if (text === '') {
    return [];
  }
  const groups: number[] = [];
  const parts = text.split(':');
  for (const [index, part] of parts.entries()) {
    if (index === parts.length - 1 && part.includes('.')) {
      const v4 = parseIpv4(part);
      if (v4 === undefined) {
        return undefined;
      }
      const [a = 0, b = 0, c = 0, d = 0] = v4;
      groups.push((a << 8) | b, (c << 8) | d);
      continue;
    }
    if (!/^[0-9a-fA-F]{1,4}$/.test(part)) {
      return undefined;
    }
    groups.push(parseInt(part, 16));
  }
  return groups;
}

/** Eight 16-bit groups, or undefined. Handles `::` and a trailing dotted quad; drops a `%zone`. */
function parseIpv6(text: string): number[] | undefined {
  const withoutZone = text.split('%')[0] ?? '';
  const unbracketed = withoutZone.replace(/^\[|\]$/g, '');
  const halves = unbracketed.split('::');
  if (halves.length > 2) {
    return undefined;
  }
  const head = parseGroups(halves[0] ?? '');
  const tail = halves.length === 2 ? parseGroups(halves[1] ?? '') : [];
  if (head === undefined || tail === undefined) {
    return undefined;
  }
  if (halves.length === 1) {
    return head.length === 8 ? head : undefined;
  }
  const missing = 8 - head.length - tail.length;
  if (missing < 1) {
    return undefined;
  }
  return [...head, ...(new Array(missing).fill(0) as number[]), ...tail];
}

function isIpv4Mapped(groups: readonly number[]): boolean {
  return groups.slice(0, 5).every((g) => g === 0) && groups[5] === 0xffff;
}
