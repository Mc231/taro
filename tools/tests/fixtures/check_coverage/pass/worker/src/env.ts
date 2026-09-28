/** Type-only module: istanbul reports no statements for it. */
import type { X } from './x';
export type Environment = 'dev' | 'prod';
export interface Env {
  readonly A: string; // ; and } inside
  readonly B: { nested: X };
}
export { a } from './app';
