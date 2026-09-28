import { createRoute } from '@hono/zod-openapi';

const healthRoute = createRoute({
  method: 'get',
  path: '/v1/health',
  responses: { 200: { description: 'ok' } },
});
export { healthRoute };
