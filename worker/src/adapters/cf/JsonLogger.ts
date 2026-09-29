import { redactFields } from '../../logging/redact';
import type { Clock } from '../../ports/Clock';
import type { LogFields, LogLevel, Logger } from '../../ports/Logger';

const LEVEL_RANK: Readonly<Record<LogLevel, number>> = { debug: 0, info: 1, warn: 2, error: 3 };

/**
 * Structured JSON logger (03 §14.1). One line per event, redacted, written to
 * `sink` (Workers Logs via `consoleSink` in production).
 */
export class JsonLogger implements Logger {
  constructor(
    private readonly clock: Clock,
    private readonly sink: (line: string) => void,
    private readonly minLevel: LogLevel = 'info',
  ) {}

  log(level: LogLevel, event: string, fields?: LogFields): void {
    if (LEVEL_RANK[level] < LEVEL_RANK[this.minLevel]) {
      return;
    }
    const line = { ts: this.clock.now().toISOString(), level, event, ...redactFields(fields) };
    this.sink(JSON.stringify(line));
  }
}

/** Workers Logs picks up `console.log`; this adapter is the only console user. */
export function consoleSink(line: string): void {
  // eslint-disable-next-line no-console -- the Logger adapter is the one allowed console call (03 §14.1)
  console.log(line);
}
