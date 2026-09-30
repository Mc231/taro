/**
 * A minimal YAML reader for block mappings and block sequences of plain or
 * quoted scalars: exactly the shape of `tools/store_copy/banned_phrases.yaml`.
 * Flow collections, anchors, multi-line scalars and documents are not
 * supported and throw, so a format change fails loudly instead of being
 * misread.
 */
export type YamlValue = string | YamlValue[] | { [key: string]: YamlValue };

interface Line {
  readonly indent: number;
  readonly text: string;
  readonly number: number;
}

function stripComment(text: string): string {
  let quote: string | null = null;
  for (let i = 0; i < text.length; i++) {
    const ch = text.charAt(i);
    if (quote !== null) {
      if (ch === quote) {
        quote = null;
      }
    } else if (ch === '"' || ch === "'") {
      quote = ch;
    } else if (ch === '#' && (i === 0 || /\s/u.test(text.charAt(i - 1)))) {
      return text.slice(0, i);
    }
  }
  return text;
}

function scalar(raw: string, line: number): string {
  const text = raw.trim();
  if (text.startsWith('"')) {
    return JSON.parse(text) as string;
  }
  if (text.startsWith("'")) {
    if (!text.endsWith("'") || text.length < 2) {
      throw new Error(`line ${String(line)}: unterminated quoted scalar`);
    }
    return text.slice(1, -1).replaceAll("''", "'");
  }
  if (/^[[{&*!|>]/u.test(text)) {
    throw new Error(`line ${String(line)}: unsupported YAML syntax`);
  }
  return text;
}

export function parseYaml(text: string): YamlValue {
  const lines: Line[] = [];
  text.split(/\r?\n/u).forEach((raw, index) => {
    const body = stripComment(raw).trimEnd();
    if (body.trim() === '') {
      return;
    }
    const indent = body.length - body.trimStart().length;
    lines.push({ indent, text: body.trimStart(), number: index + 1 });
  });
  let pos = 0;

  function block(indent: number): YamlValue {
    const first = lines[pos];
    if (first === undefined || first.indent < indent) {
      return '';
    }
    return first.text.startsWith('- ') || first.text === '-'
      ? sequence(first.indent)
      : mapping(first.indent);
  }

  function sequence(indent: number): YamlValue[] {
    const items: YamlValue[] = [];
    for (
      let line = lines[pos];
      line?.indent === indent && line.text.startsWith('-');
      line = lines[pos]
    ) {
      pos++;
      const rest = line.text.slice(1).trim();
      items.push(rest === '' ? block(indent + 1) : scalar(rest, line.number));
    }
    return items;
  }

  function mapping(indent: number): Record<string, YamlValue> {
    const map: Record<string, YamlValue> = {};
    for (let line = lines[pos]; line?.indent === indent; line = lines[pos]) {
      const match = /^([^:]+):(?:\s+(.*))?$/u.exec(line.text);
      if (match === null) {
        throw new Error(`line ${String(line.number)}: expected "key: value"`);
      }
      pos++;
      const key = scalar(match[1] ?? '', line.number);
      const rest = match[2] ?? '';
      map[key] = rest === '' ? block(indent + 1) : scalar(rest, line.number);
    }
    return map;
  }

  const root = block(0);
  const extra = lines[pos];
  if (extra !== undefined) {
    throw new Error(`line ${String(extra.number)}: unexpected indentation`);
  }
  return root;
}
