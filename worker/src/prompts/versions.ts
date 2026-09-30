import { toHex, utf8 } from '../crypto/encoding';
import type { Crypto } from '../ports/Crypto';
import { READING_TEMPLATES, templateFiles, type PromptVersion } from './templates';

/**
 * SHA-256 over a prompt version's template files (06 §7): for each file,
 * sorted by name, `<name>\n<length in UTF-16 code units>\n<text>\n`. A released
 * version's hash is pinned in `versions.lock.json`, and a test fails when the
 * templates change without a new version directory.
 */
export async function promptVersionHash(version: PromptVersion, crypto: Crypto): Promise<string> {
  const canonical = templateFiles(READING_TEMPLATES[version])
    .map(([name, text]) => `${name}\n${String(text.length)}\n${text}\n`)
    .join('');
  return toHex(await crypto.sha256(utf8(canonical)));
}
