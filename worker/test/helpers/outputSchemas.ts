import spreadsFeed from '../../src/generated/deck/spreads.json';
import { buildReadingPrompt } from '../../src/prompts/build';
import type { OutputSchema } from '../../src/prompts/templates';

type Node = Readonly<Record<string, unknown>>;

function isNode(value: unknown): value is Node {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** The per-request output schema of every generated spread (03 §9.2), by spread ID. */
export function spreadSchemas(): [string, OutputSchema][] {
  return spreadsFeed.spreads.map((spread) => {
    const built = buildReadingPrompt({
      spreadId: spread.id,
      locale: 'en',
      cards: spread.positions.map((position, i) => ({
        positionId: position.id,
        cardId: `major_${String(i).padStart(2, '0')}`,
        reversed: false,
      })),
    });
    if (!built.ok) {
      throw new Error(built.error);
    }
    return [spread.id, built.input.outputSchema];
  });
}

/** Every schema node of `type: object`, with its JSON path. */
export function objectNodes(schema: unknown, path = '$'): [string, Node][] {
  if (!isNode(schema)) {
    return [];
  }
  const own: [string, Node][] = schema['type'] === 'object' ? [[path, schema]] : [];
  const properties = isNode(schema['properties']) ? schema['properties'] : {};
  return [
    ...own,
    ...Object.entries(properties).flatMap(([name, sub]) => objectNodes(sub, `${path}.${name}`)),
    ...(isNode(schema['items']) ? objectNodes(schema['items'], `${path}[]`) : []),
  ];
}

/** Every keyword used anywhere in the schema (property names excluded). */
export function schemaKeywords(schema: unknown): Set<string> {
  const found = new Set<string>();
  const walk = (node: unknown): void => {
    if (Array.isArray(node)) {
      node.forEach(walk);
      return;
    }
    if (!isNode(node)) {
      return;
    }
    for (const [key, value] of Object.entries(node)) {
      if (key === 'properties' && isNode(value)) {
        Object.values(value).forEach(walk);
      } else {
        found.add(key);
        walk(value);
      }
    }
  };
  walk(schema);
  return found;
}
