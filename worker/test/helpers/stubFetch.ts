import { toBase64 } from '../../src/crypto/encoding';

/** A recorded outbound request. */
export interface RecordedRequest {
  readonly url: string;
  readonly method: string;
  readonly headers: Headers;
  readonly body: string;
}

type Responder = (request: RecordedRequest) => Response | Promise<Response>;

/**
 * `fetch` stub injected into adapter constructors (03 §15.2): no network.
 * Responders are consumed in order; the last one used repeats when none is queued.
 */
export class StubFetch {
  readonly requests: RecordedRequest[] = [];
  private readonly responders: Responder[] = [];
  private last: Responder | undefined;

  reply(...responders: (Responder | Response)[]): this {
    for (const r of responders) {
      this.responders.push(r instanceof Response ? () => r.clone() : r);
    }
    return this;
  }

  readonly fetch: typeof fetch = async (input, init) => {
    const request = new Request(input, init);
    const recorded: RecordedRequest = {
      url: request.url,
      method: request.method,
      headers: request.headers,
      body: new TextDecoder().decode(await request.arrayBuffer()),
    };
    this.requests.push(recorded);
    const responder = this.responders.shift() ?? this.last;
    this.last = responder;
    if (responder === undefined) {
      throw new TypeError('StubFetch: no responder');
    }
    return responder(recorded);
  };
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

export function networkError(): never {
  throw new TypeError('network error');
}

/** PKCS#8 PEM of a generated private key (DeviceCheck `.p8`, service-account key). */
export async function pkcs8Pem(key: CryptoKey): Promise<string> {
  const der = new Uint8Array((await crypto.subtle.exportKey('pkcs8', key)) as ArrayBuffer);
  const lines = toBase64(der).match(/.{1,64}/g) ?? [];
  return `-----BEGIN PRIVATE KEY-----\n${lines.join('\n')}\n-----END PRIVATE KEY-----\n`; // gitleaks:allow (template for a test-generated key)
}
