import type { IdGenerator } from '../../src/ports/IdGenerator';

/** Sequential, UUID-shaped IDs: `00000000-0000-4000-8000-000000000001`, … */
export class SeqIdGenerator implements IdGenerator {
  private next = 1;

  constructor(private readonly prefix = '00000000') {}

  private seq(): string {
    const n = this.next++;
    return n.toString(16).padStart(12, '0');
  }

  uuid(): string {
    return `${this.prefix}-0000-4000-8000-${this.seq()}`;
  }

  uuidV7(): string {
    return `${this.prefix}-0000-7000-8000-${this.seq()}`;
  }

  opaque(): string {
    return `opaque${this.seq()}`;
  }
}
