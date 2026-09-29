import type { LogFields, LogValue } from '../ports/Logger';

/**
 * Last-line redaction for log output (BE13, 03 §13). Callers must not pass
 * sensitive values at all; this only guards against mistakes.
 */
export const REDACTED = '[redacted]';

/** Field names whose values are never logged (secrets, tokens, content, IPs). */
const SENSITIVE_KEY =
  /secret|token|authorization|password|question|^reading$|readingtext|output|^prompt$|^body$|^ip$|ipaddress|attestation|devicekey|signature/i;

/** JWT-shaped values and bearer credentials. */
const SENSITIVE_VALUE = /eyJ[\w-]{4,}\.[\w-]{4,}|bearer\s+\S+/i;

/** Full install IDs are reduced to `inst8` (the first 8 characters). */
export function inst8(installId: string | undefined): string | undefined {
  return installId === undefined ? undefined : installId.slice(0, 8);
}

function redactValue(key: string, value: LogValue): LogValue {
  if (value === undefined || value === null) {
    return value;
  }
  if (SENSITIVE_KEY.test(key)) {
    return REDACTED;
  }
  if (typeof value === 'string' && SENSITIVE_VALUE.test(value)) {
    return REDACTED;
  }
  return value;
}

export function redactFields(fields: LogFields | undefined): Record<string, LogValue> {
  const out: Record<string, LogValue> = {};
  if (fields === undefined) {
    return out;
  }
  for (const [key, value] of Object.entries(fields)) {
    const redacted = redactValue(key, value);
    if (redacted !== undefined) {
      out[key] = redacted;
    }
  }
  return out;
}
