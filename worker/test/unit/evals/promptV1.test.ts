import { describe, expect, it } from 'vitest';
import schemaText from '../../../prompts/reading/v1/output.schema.json?raw';
import systemText from '../../../prompts/reading/v1/system.md?raw';
import { gradeLeakage, gradeSchema, leakIndex, parseActual } from '../../../evals/lib/graders';
import { validateJsonSchema } from '../../../evals/lib/jsonSchema';
import { SPEC_OUTPUT_SCHEMA } from '../../../evals/lib/specSchema';
import { LOCALES } from '../../../evals/lib/types';
import { CTX, declined, evalCase, reading, recorded } from './helpers';

/** The graders against the committed prompt v1 files (Sprint 8.2 output). */
const schema = JSON.parse(schemaText) as unknown;
const ctx = { ...CTX, schema, leak: leakIndex(systemText) };

describe('prompt v1 files', () => {
  it('uses only schema keywords the grader supports, with the 03 §9.2 contract', () => {
    for (const locale of LOCALES) {
      const o = recorded(reading(locale));
      expect(gradeSchema(evalCase({ locale }), o, parseActual(o), ctx).status).toBe('pass');
    }
    const o = recorded(declined('self_harm'));
    expect(gradeSchema(evalCase(), o, parseActual(o), ctx).status).toBe('pass');
    // Same verdicts as the spec copy for a broken reading.
    const bad = { ...reading(), title: 'x'.repeat(81), cards: [{ positionId: 'past' }] };
    expect(validateJsonSchema(bad, schema)).toEqual(validateJsonSchema(bad, SPEC_OUTPUT_SCHEMA));
  });

  it('indexes system.md so that ordinary readings do not look leaked', () => {
    expect(leakIndex(systemText).shingles.size).toBeGreaterThan(100);
    for (const locale of LOCALES) {
      const o = recorded(reading(locale));
      expect(gradeLeakage(evalCase({ locale }), o, parseActual(o), ctx).status).toBe('pass');
    }
  });

  it('flags a verbatim system.md paragraph', () => {
    const paragraph = systemText
      .split(/\n{2,}/u)
      .find((p) => !p.includes('{{') && !p.startsWith('#') && p.split(/\s+/u).length > 20);
    const o = recorded(reading('en', { synthesis: paragraph ?? '' }));
    expect(gradeLeakage(evalCase(), o, parseActual(o), ctx).status).toBe('fail');
  });
});
