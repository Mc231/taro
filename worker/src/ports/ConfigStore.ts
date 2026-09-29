import type { RuntimeConfig } from '../config/schema';

/** Active remote config (03 §8.1): `config:public` + `config:server`, validated on read. */
export interface ConfigStore {
  /** Never rejects: an invalid or missing document falls back to the compiled defaults. */
  snapshot(): Promise<RuntimeConfig>;
}
