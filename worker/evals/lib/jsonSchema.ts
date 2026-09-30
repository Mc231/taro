/**
 * A small JSON Schema validator for the subset `output.schema.json` uses
 * (03 §9.2): `type`, `enum`, `const`, `required`, `properties`,
 * `additionalProperties`, `items`, `minItems`, `maxItems`, `minLength`,
 * `maxLength`, `pattern`. String lengths count code points, as JSON Schema
 * does. An unsupported keyword is reported once, so the schema cannot grow a
 * rule the grader silently ignores.
 */
type Schema = Readonly<Record<string, unknown>>;

const SUPPORTED = new Set([
  'type',
  'enum',
  'const',
  'required',
  'properties',
  'additionalProperties',
  'items',
  'minItems',
  'maxItems',
  'minLength',
  'maxLength',
  'pattern',
  // annotations only
  '$schema',
  '$id',
  'title',
  'description',
  '$comment',
  'examples',
  'default',
]);

function isSchema(value: unknown): value is Schema {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function typeOf(value: unknown): string {
  if (value === null) {
    return 'null';
  }
  if (Array.isArray(value)) {
    return 'array';
  }
  if (typeof value === 'number') {
    return Number.isInteger(value) ? 'integer' : 'number';
  }
  return typeof value;
}

function matchesType(value: unknown, type: unknown): boolean {
  const types = Array.isArray(type) ? (type as unknown[]) : [type];
  const actual = typeOf(value);
  return types.some((t) => t === actual || (t === 'number' && actual === 'integer'));
}

function num(schema: Schema, key: string): number | null {
  const value = schema[key];
  return typeof value === 'number' ? value : null;
}

export function validateJsonSchema(value: unknown, schema: unknown): string[] {
  const errors: string[] = [];
  const unsupported = new Set<string>();
  walk(value, schema, '$', errors, unsupported);
  for (const keyword of unsupported) {
    errors.push(`schema keyword "${keyword}" is not supported by the grader`);
  }
  return errors;
}

function walk(
  value: unknown,
  schema: unknown,
  path: string,
  errors: string[],
  unsupported: Set<string>,
): void {
  if (!isSchema(schema)) {
    return;
  }
  for (const key of Object.keys(schema)) {
    if (!SUPPORTED.has(key)) {
      unsupported.add(key);
    }
  }
  if (schema['type'] !== undefined && !matchesType(value, schema['type'])) {
    errors.push(`${path}: expected ${JSON.stringify(schema['type'])}, got ${typeOf(value)}`);
    return;
  }
  if (Array.isArray(schema['enum']) && !(schema['enum'] as unknown[]).includes(value)) {
    errors.push(`${path}: ${JSON.stringify(value)} is not one of the allowed values`);
  }
  if ('const' in schema && schema['const'] !== value) {
    errors.push(`${path}: must equal ${JSON.stringify(schema['const'])}`);
  }
  if (typeof value === 'string') {
    const length = Array.from(value).length;
    const max = num(schema, 'maxLength');
    const min = num(schema, 'minLength');
    if (max !== null && length > max) {
      errors.push(`${path}: ${String(length)} characters > maxLength ${String(max)}`);
    }
    if (min !== null && length < min) {
      errors.push(`${path}: ${String(length)} characters < minLength ${String(min)}`);
    }
    if (typeof schema['pattern'] === 'string' && !new RegExp(schema['pattern'], 'u').test(value)) {
      errors.push(`${path}: does not match ${schema['pattern']}`);
    }
  }
  if (Array.isArray(value)) {
    const max = num(schema, 'maxItems');
    const min = num(schema, 'minItems');
    if (max !== null && value.length > max) {
      errors.push(`${path}: ${String(value.length)} items > maxItems ${String(max)}`);
    }
    if (min !== null && value.length < min) {
      errors.push(`${path}: ${String(value.length)} items < minItems ${String(min)}`);
    }
    (value as unknown[]).forEach((item, index) => {
      walk(item, schema['items'], `${path}[${String(index)}]`, errors, unsupported);
    });
  }
  if (isSchema(value)) {
    const properties = isSchema(schema['properties']) ? schema['properties'] : {};
    if (Array.isArray(schema['required'])) {
      for (const key of schema['required'] as unknown[]) {
        if (typeof key === 'string' && !(key in value)) {
          errors.push(`${path}: missing required "${key}"`);
        }
      }
    }
    for (const [key, child] of Object.entries(value)) {
      if (key in properties) {
        walk(child, properties[key], `${path}.${key}`, errors, unsupported);
      } else if (schema['additionalProperties'] === false) {
        errors.push(`${path}: unexpected property "${key}"`);
      } else {
        walk(child, schema['additionalProperties'], `${path}.${key}`, errors, unsupported);
      }
    }
  }
}
