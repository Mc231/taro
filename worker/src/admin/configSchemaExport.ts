import { z } from 'zod';
import { RemoteConfigFileSchema } from '../config/schema';

/** Where `scripts/export-config-schema.ts` writes the export (relative to `worker/`). */
export const CONFIG_JSON_SCHEMA_PATH = 'config/remote_config.schema.json';

/**
 * JSON Schema (draft 2020-12) of `config/remote_config.default.json`,
 * exported from the one zod schema (03 §8.1, RC8) for
 * `tools/check_remote_config.py`. Cross-key rules (unique lists, ordered
 * budget floors) are zod refinements and are not part of the export.
 */
export function remoteConfigJsonSchema(): Record<string, unknown> {
  return {
    ...z.toJSONSchema(RemoteConfigFileSchema),
    $id: 'https://taro.vshyrochuk.com/schemas/remote_config.schema.json',
    title: 'Taro remote config (config:public + config:server)',
    description:
      'Generated from worker/src/config/schema.ts by scripts/export-config-schema.ts; do not edit.',
  };
}

/** The committed file's exact text (2-space JSON plus a trailing newline). */
export function renderRemoteConfigJsonSchema(): string {
  return `${JSON.stringify(remoteConfigJsonSchema(), null, 2)}\n`;
}
