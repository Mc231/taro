/**
 * Structured logging port (03 §14.1, BE13). Log lines never carry the question,
 * AI output, full install ID (only `inst8`), the install secret, tokens or IPs.
 */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export type LogValue = string | number | boolean | null | undefined;

export type LogFields = Readonly<Record<string, LogValue>>;

export interface Logger {
  log(level: LogLevel, event: string, fields?: LogFields): void;
}
