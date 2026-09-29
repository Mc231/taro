import { describe, expect, it } from 'vitest';
import {
  clientNetwork,
  ipPrefixHash,
  rateLimit,
  REGISTRATIONS_PER_PREFIX_PER_DAY,
  SOFT_COUNTER_TTL_SEC,
  SoftLimits,
  utcDay,
  type ClientNetwork,
} from '../../../src/http/middleware/rateLimit';
import { bindings, createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { APP_HEADERS, errorOf, testApp, testAuth } from '../../helpers/app';

function limitedApp(h: TestHarness) {
  return testApp(h, (a) => {
    a.use('/v1/t/*', testAuth);
    a.get('/v1/t/burst', rateLimit(h.deps, 'install'), (c) => c.text('ok'));
    a.get('/v1/t/readings', rateLimit(h.deps, 'readings'), (c) => c.text('ok'));
    a.get('/v1/t/ip', rateLimit(h.deps, 'ipPrefix'), (c) => c.text('ok'));
    a.get('/v1/t/net', (c) => c.json(clientNetwork(c)));
  });
}

/** Unique documentation-range IPv6 /64 per call, so tests never share KV counters. */
function uniqueNetwork(asn?: number): ClientNetwork {
  const n = uniqueId('n').slice(-4);
  return { ip: `2001:db8:${n}:1::5`, asn };
}

describe('rateLimit middleware (RL_BURST / RL_READINGS)', () => {
  it('limits per install on RL_BURST with 429 RATE_LIMITED reason=burst and Retry-After', async () => {
    const h = createHarness();
    h.burst.limitPerKey = 2;
    const app = limitedApp(h);
    const install = uniqueId();
    const headers = { ...APP_HEADERS, 'X-Test-Install': install };

    expect((await app.request('/v1/t/burst', { headers })).status).toBe(200);
    expect((await app.request('/v1/t/burst', { headers })).status).toBe(200);
    const limited = await app.request('/v1/t/burst', { headers });

    expect(limited.status).toBe(429);
    expect(limited.headers.get('Retry-After')).toBe('60');
    expect(await errorOf(limited)).toMatchObject({
      code: 'RATE_LIMITED',
      retryable: true,
      retryAfterSec: 60,
      details: { reason: 'burst' },
    });
    expect(h.burst.keys).toEqual([`inst:${install}`, `inst:${install}`, `inst:${install}`]);
    expect(h.readings.keys).toEqual([]);
    expect(h.metrics.points).toEqual([{ event: 'rate_limited', code: 'burst', platform: 'ios' }]);
  });

  it('uses RL_READINGS for holds and readings', async () => {
    const h = createHarness();
    h.readings.limitPerKey = 0;
    const res = await limitedApp(h).request('/v1/t/readings', {
      headers: { 'X-Test-Install': 'inst-r' },
    });

    expect(res.status).toBe(429);
    expect(h.readings.keys).toEqual(['inst:inst-r']);
    expect(h.metrics.points).toEqual([{ event: 'rate_limited', code: 'burst' }]);
  });

  it('skips install scopes when no install is authenticated', async () => {
    const h = createHarness();
    h.burst.limitPerKey = 0;
    expect((await limitedApp(h).request('/v1/t/burst')).status).toBe(200);
    expect(h.burst.keys).toEqual([]);
  });

  it('keys public routes by the HMAC of the IP prefix, never the raw IP', async () => {
    const h = createHarness();
    const app = limitedApp(h);
    for (const ip of [
      '203.0.113.7',
      '203.0.113.200',
      '198.51.100.7',
      '2001:db8:1:2::1',
      '2001:db8:1:2:ffff::9',
    ]) {
      await app.request('/v1/t/ip', { headers: { 'CF-Connecting-IP': ip } });
    }
    await app.request('/v1/t/ip');

    const [v4a, v4b, v4c, v6a, v6b, unknown] = h.burst.keys;
    expect(v4a).toMatch(/^ip:[A-Za-z0-9_-]{22}$/);
    expect(v4a).toBe(v4b);
    expect(v4a).not.toBe(v4c);
    expect(v6a).toBe(v6b);
    expect(unknown).toBe(`ip:${await ipPrefixHash(h.deps, undefined)}`);
    expect(h.burst.keys.join()).not.toContain('203.0.113');
    expect(h.burst.keys.join()).not.toContain('2001:db8');
  });

  it('works against the real miniflare RL_READINGS binding (6 per 60 s)', async () => {
    const h = createHarness({
      overrides: { rateLimiters: { burst: bindings.RL_BURST, readings: bindings.RL_READINGS } },
    });
    const app = limitedApp(h);
    const headers = { 'X-Test-Install': uniqueId('rl') };
    const statuses: number[] = [];
    for (let i = 0; i < 7; i++) {
      statuses.push((await app.request('/v1/t/readings', { headers })).status);
    }

    expect(statuses).toEqual([200, 200, 200, 200, 200, 200, 429]);
  });

  it('reads the client IP and ASN from CF-Connecting-IP and request.cf', async () => {
    const h = createHarness();
    const app = limitedApp(h);
    const req = new Request('http://localhost/v1/t/net', {
      headers: { 'CF-Connecting-IP': '203.0.113.9' },
      cf: { asn: 21928 },
    });
    expect(await (await app.request(req)).json()).toEqual({ ip: '203.0.113.9', asn: 21928 });
    expect(await (await app.request('/v1/t/net')).json()).toEqual({});
  });
});

describe('ipPrefixHash', () => {
  it('is a keyed, truncated HMAC of the prefix', async () => {
    const a = createHarness();
    const b = createHarness({ ipHashKey: 'another-ip-hash-key-0123456789' });
    const hash = await ipPrefixHash(a.deps, '203.0.113.7');

    expect(hash).toHaveLength(22);
    expect(await ipPrefixHash(a.deps, '203.0.113.99')).toBe(hash);
    expect(await ipPrefixHash(b.deps, '203.0.113.7')).not.toBe(hash);
  });

  it('formats the UTC day', () => {
    expect(utcDay(new Date('2026-09-26T23:59:59.999Z'))).toBe('20260926');
  });
});

describe('SoftLimits (RL_KV soft counters)', () => {
  it('caps low-trust free readings per IP prefix per UTC day (3)', async () => {
    const h = createHarness();
    const limits = new SoftLimits(h.deps);
    const net = uniqueNetwork();
    const results = [];
    for (let i = 0; i < 4; i++) {
      results.push(await limits.consumeLowTrustFree(net));
    }

    expect(results.map((r) => r.allowed)).toEqual([true, true, true, false]);
    expect(results[3]).toEqual({ allowed: false, count: 3, limit: 3 });

    const hash = await ipPrefixHash(h.deps, net.ip);
    const listed = await bindings.RL_KV.list({ prefix: `lt:ip:${hash}:` });
    expect(listed.keys.map((k) => k.name)).toEqual([`lt:ip:${hash}:20260926`]);
    const expiration = listed.keys[0]?.expiration ?? 0;
    expect(expiration).toBeGreaterThan(0);
    expect(expiration * 1000 - Date.now()).toBeLessThanOrEqual(SOFT_COUNTER_TTL_SEC * 1000);

    h.clock.advance({ days: 1 });
    expect((await limits.consumeLowTrustFree(net)).allowed).toBe(true);
  });

  it('gives CGNAT carrier prefixes the higher cap (20, RC65)', async () => {
    const h = createHarness();
    h.config.set({ 'abuse.lowTrust.cgnatAsns': [64500] });
    const limits = new SoftLimits(h.deps);

    const cgnat = await limits.consumeLowTrustFree(uniqueNetwork(64500));
    expect(cgnat.limit).toBe(20);
    const plain = await limits.consumeLowTrustFree(uniqueNetwork(64501));
    expect(plain.limit).toBe(3);
    const noAsn = await limits.consumeLowTrustFree(uniqueNetwork());
    expect(noAsn.limit).toBe(3);
  });

  it('caps type:none registrations per prefix (5) without blocking attested ones', async () => {
    const h = createHarness();
    const limits = new SoftLimits(h.deps);
    const net = uniqueNetwork();
    const none = [];
    for (let i = 0; i < 6; i++) {
      none.push(await limits.consumeRegistration(net, 'none'));
    }

    expect(none.slice(0, 5).every((r) => r.allowed)).toBe(true);
    expect(none[5]).toEqual({ allowed: false, reason: 'noneCap' });
    expect(await limits.consumeRegistration(net, 'attested')).toEqual({ allowed: true });
  });

  it('caps registrations of any type per prefix per day (50)', async () => {
    const h = createHarness();
    const limits = new SoftLimits(h.deps);
    const net = uniqueNetwork();
    const hash = await ipPrefixHash(h.deps, net.ip);
    await bindings.RL_KV.put(
      `reg:all:${hash}:20260926`,
      String(REGISTRATIONS_PER_PREFIX_PER_DAY - 1),
    );

    expect(await limits.consumeRegistration(net, 'attested')).toEqual({ allowed: true });
    expect(await limits.consumeRegistration(net, 'attested')).toEqual({
      allowed: false,
      reason: 'prefixCap',
    });
    expect(await limits.consumeRegistration(net, 'none')).toEqual({
      allowed: false,
      reason: 'prefixCap',
    });
  });

  it('treats a corrupt counter value as zero', async () => {
    const h = createHarness();
    const net = uniqueNetwork();
    const hash = await ipPrefixHash(h.deps, net.ip);
    await bindings.RL_KV.put(`lt:ip:${hash}:20260926`, 'garbage');

    expect(await new SoftLimits(h.deps).consumeLowTrustFree(net)).toMatchObject({
      allowed: true,
      count: 1,
    });
  });

  it('alerts on the low-trust (platform, version) bucket at 80 % and 100 %, never blocks', async () => {
    const h = createHarness();
    h.config.set({ 'abuse.lowTrust.alertPerBucketPerDay': 10 });
    const limits = new SoftLimits(h.deps);
    const version = `1.0.${uniqueId('v').slice(-3)}`;
    const counts = [];
    for (let i = 0; i < 12; i++) {
      counts.push(await limits.recordLowTrustBucket('android', version));
    }

    expect(counts).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    expect(h.alerter.alerts.map((a) => a.fields?.['count'])).toEqual([8, 10]);
    expect(h.alerter.alerts[0]).toMatchObject({
      kind: 'low_trust_bucket',
      fields: { platform: 'android', appVersion: version, limit: 10, day: '20260926' },
    });
    const listed = await bindings.RL_KV.list({ prefix: `lt:bucket:android:${version}:` });
    expect(listed.keys.map((k) => k.name)).toEqual([`lt:bucket:android:${version}:20260926`]);
  });
});
