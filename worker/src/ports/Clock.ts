/** Time port (03 §1, QA9). Code never calls `Date.now()` / `new Date()` for "now" directly. */
export interface Clock {
  now(): Date;
}
