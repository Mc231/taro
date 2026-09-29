import type { Clock } from '../../ports/Clock';

/** Production clock. The only place that reads the system time (QA9). */
export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}
