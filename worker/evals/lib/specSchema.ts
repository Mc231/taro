/**
 * The output schema as written in 03 §9.2, used when the prompt version under
 * test has no `output.schema.json` yet (a template, expanded per spread like
 * the file). A real run grades against the file.
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
      type: 'object',
      properties: {
        '<positionId>': {
          type: 'object',
          required: ['cardId', 'reversed', 'interpretation'],
          properties: {
            cardId: { type: 'string' },
            reversed: { type: 'boolean' },
            interpretation: { type: 'string', maxLength: 900 },
          },
          additionalProperties: false,
        },
      },
      required: ['<positionId>'],
      additionalProperties: false,
    },
    synthesis: { type: 'string', maxLength: 1400 },
    reflectionPrompts: {
      type: 'object',
      properties: { 'prompt<n>': { type: 'string', maxLength: 200 } },
      required: ['prompt<n>'],
      additionalProperties: false,
    },
  },
  additionalProperties: false,
} as const;
