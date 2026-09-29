import type { LogFields, LogLevel, Logger } from '../../src/ports/Logger';

export interface LogEntry {
  readonly level: LogLevel;
  readonly event: string;
  readonly fields: LogFields;
}

/** JWT-shaped strings and bearer credentials must never be logged (BE13). */
const ALWAYS_SENSITIVE: readonly RegExp[] = [/eyJ[\w-]{4,}\.[\w-]{4,}/, /bearer\s+\S+/i];

/**
 * Captures raw log calls (before the production redactor) so tests prove
 * code never even passes sensitive values to the logger (03 §15.3, BE13).
 */
export class CapturingLogger implements Logger {
  readonly entries: LogEntry[] = [];

  log(level: LogLevel, event: string, fields: LogFields = {}): void {
    this.entries.push({ level, event, fields });
  }

  /** Each entry as the JSON line it would produce. */
  lines(): string[] {
    return this.entries.map((e) => JSON.stringify({ level: e.level, event: e.event, ...e.fields }));
  }

  find(event: string): LogEntry[] {
    return this.entries.filter((e) => e.event === event);
  }

  /**
   * Throws if any captured line contains one of `sensitive` (question, AI
   * output, install secret, full install ID, token, IP, …) or a JWT/bearer
   * credential.
   */
  expectNoSensitive(...sensitive: readonly string[]): void {
    const findings: string[] = [];
    for (const line of this.lines()) {
      for (const value of sensitive) {
        if (value !== '' && line.includes(value)) {
          findings.push(`sensitive value ${JSON.stringify(value.slice(0, 12))}… in ${line}`);
        }
      }
      for (const pattern of ALWAYS_SENSITIVE) {
        if (pattern.test(line)) {
          findings.push(`${String(pattern)} in ${line}`);
        }
      }
    }
    if (findings.length > 0) {
      throw new Error(`expectNoSensitive failed:\n${findings.join('\n')}`);
    }
  }
}
