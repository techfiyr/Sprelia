import type { FastifyPluginAsync } from 'fastify';

/**
 * Liveness check for Cloud Run and uptime monitors. Public, unauthenticated and
 * deliberately minimal: no version, environment, hostnames, dependencies or timings.
 */
export const healthRoutes: FastifyPluginAsync = async (app) => {
  app.get('/health', { config: { rateLimit: false } }, async (_request, reply) => {
    reply.header('cache-control', 'no-store');
    return { status: 'ok' };
  });
};
