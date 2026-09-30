/**
 * The output schema as written in 03 §9.2, used when the prompt version under
 * test has no `output.schema.json` yet. A real run grades against the file.
 */
export const SPEC_OUTPUT_SCHEMA = {
  type: 'object',
  required: ['classification', 'title', 'overview', 'cards', 'synthesis', 'reflectionPrompts'],
  properties: {
    classification: {
      enum: [
        'none',
        'health',
        'pregnancy',
        'death',
        'legal',
        'financial',
        'gambling',
        'self_harm',
        'harm_to_others',
        'sexual_minors',
        'hate_or_harassment',
      ],
    },
    title: { type: 'string', maxLength: 80 },
    overview: { type: 'string', maxLength: 700 },
    cards: {
      type: 'array',
      items: {
        type: 'object',
        required: ['positionId', 'cardId', 'reversed', 'interpretation'],
        properties: {
          positionId: { type: 'string' },
          cardId: { type: 'string' },
          reversed: { type: 'boolean' },
          interpretation: { type: 'string', maxLength: 900 },
        },
        additionalProperties: false,
      },
    },
    synthesis: { type: 'string', maxLength: 1400 },
    reflectionPrompts: {
      type: 'array',
      items: { type: 'string', maxLength: 200 },
      minItems: 1,
      maxItems: 3,
    },
  },
  additionalProperties: false,
} as const;
