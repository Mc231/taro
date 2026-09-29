/**
 * Canonical JSON for request hashing (03 §2.3): object keys sorted
 * recursively, no insignificant whitespace, so `{"a":1,"b":2}` and
 * `{ "b": 2, "a": 1 }` hash the same. Input that is not JSON is returned as is.
 */
export function canonicalJson(text: string): string {
  if (text.trim() === '') {
    return '';
  }
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    return text;
  }
  return JSON.stringify(sortKeys(value));
}

function sortKeys(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(sortKeys);
  }
  if (value !== null && typeof value === 'object') {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(
      Object.keys(record)
        .sort()
        .map((key) => [key, sortKeys(record[key])]),
    );
  }
  return value;
}
