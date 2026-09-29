import { DEFAULT_RUNTIME_CONFIG } from '../../src/config/defaults';
import type { RuntimeConfig } from '../../src/config/schema';
import type { ConfigStore } from '../../src/ports/ConfigStore';

/** Compiled defaults plus per-test overrides. */
export class FakeConfigStore implements ConfigStore {
  private current: RuntimeConfig;
  reads = 0;

  constructor(overrides: Partial<RuntimeConfig> = {}) {
    this.current = { ...DEFAULT_RUNTIME_CONFIG, ...overrides };
  }

  set(overrides: Partial<RuntimeConfig>): void {
    this.current = { ...this.current, ...overrides, version: this.current.version + 1 };
  }

  snapshot(): Promise<RuntimeConfig> {
    this.reads++;
    return Promise.resolve(this.current);
  }
}
