import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import { issueChallenge } from '../domain/challenge';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { ErrorEnvelopeSchema } from '../http/errors';
import { routeGuards } from '../http/routeGuards';

export const ChallengeResponseSchema = z
  .object({
    challenge: z.string(),
    expiresAt: z.iso.datetime(),
    powBits: z.int(),
  })
  .openapi('AttestChallenge', {
    description:
      'Stateless challenge (03 §3.2): base64url(nonce16 ‖ exp8 ‖ HMAC[0..16]), valid 5 minutes. powBits applies only to a `type: none` registration (§2.4).',
  });

const errorResponse = {
  content: { 'application/json': { schema: ErrorEnvelopeSchema } },
} as const;

/** `POST /v1/attest/challenge` (03 §3.2): public, `RL_BURST` keyed `ip:{prefix hash}`. */
export function registerAttestRoutes(app: OpenAPIHono<AppEnv>, deps: Deps): void {
  const challengeRoute = createRoute({
    method: 'post',
    path: '/v1/attest/challenge',
    tags: ['identity'],
    summary: 'Attestation challenge (public, rate-limited per IP prefix)',
    ...routeGuards(deps, { auth: 'public', rateLimit: 'ipPrefix' }),
    responses: {
      200: {
        description: 'A fresh challenge',
        content: { 'application/json': { schema: ChallengeResponseSchema } },
      },
      400: { description: 'Missing client headers', ...errorResponse },
      429: { description: 'Rate limited (`reason = burst`)', ...errorResponse },
    },
  });

  app.openapi(challengeRoute, async (c) => {
    const config = await deps.config.snapshot();
    const { challenge, expiresAt } = await issueChallenge(
      deps.crypto,
      deps.keys.challenge(),
      deps.clock.now(),
    );
    return c.json(
      { challenge, expiresAt: expiresAt.toISOString(), powBits: config['abuse.lowTrust.powBits'] },
      200,
    );
  });
}
