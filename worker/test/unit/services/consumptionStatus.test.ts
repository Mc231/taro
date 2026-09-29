import { describe, expect, it } from 'vitest';
import { consumptionStatus } from '../../../src/services/WebhookService';

/** `CONSUMPTION_REQUEST` consumption figure (03 §6.4, BE Q4): paid balance vs the purchase's credits. */
describe('consumptionStatus', () => {
  it.each([
    [10, 3, 1],
    [3, 3, 1],
    [2, 3, 2],
    [1, 10, 2],
    [0, 3, 3],
    [-4, 3, 3],
  ])('paid %i of %i credits → %i', (paid, credits, expected) => {
    expect(consumptionStatus(paid, credits)).toBe(expected);
  });
});
