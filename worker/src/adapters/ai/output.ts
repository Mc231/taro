import {
  parseModelOutput,
  type ExpectedReading,
  type ReadingOutput,
} from '../../prompts/templates';

/**
 * Output handling shared by the AI adapters (03 §9.2, §9.3).
 *
 * `output.schema.json`, expanded per spread (`outputSchemaFor`), is the
 * provider-neutral contract; each vendor's strict
 * mode rejects some keywords, so the adapter drops them (`stripSchemaKeywords`)
 * and the Worker's zod parse and L3 enforce them instead (RC97).
 */
type SchemaNode = unknown;

/** Removes the keywords `drop(key, value)` selects, recursively (property names are kept). */
export function stripSchemaKeywords(
  schema: SchemaNode,
  drop: (key: string, value: unknown) => boolean,
): SchemaNode {
  if (Array.isArray(schema)) {
    return schema.map((item: unknown) => stripSchemaKeywords(item, drop));
  }
  if (schema === null || typeof schema !== 'object') {
    return schema;
  }
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(schema)) {
    if (key === 'properties' && value !== null && typeof value === 'object') {
      // Keys under `properties` are field names, never keywords.
      out[key] = Object.fromEntries(
        Object.entries(value as Record<string, unknown>).map(([name, sub]) => [
          name,
          stripSchemaKeywords(sub, drop),
        ]),
      );
    } else if (!drop(key, value)) {
      out[key] = stripSchemaKeywords(value, drop);
    }
  }
  return out;
}

export type ParsedModelText =
  | { readonly ok: true; readonly output: ReadingOutput }
  | { readonly ok: false; readonly issues: readonly string[] };

/** `JSON.parse`, then zod (`parseModelOutput`: keyed wire form → `ReadingOutput`) against the drawn cards. */
export function parseModelText(text: string, expected: ExpectedReading): ParsedModelText {
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    return { ok: false, issues: ['$: not valid JSON'] };
  }
  return parseModelOutput(value, expected);
}
