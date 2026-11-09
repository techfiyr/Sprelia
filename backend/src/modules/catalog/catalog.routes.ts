import type { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import { PRACTICE_CATEGORIES } from './practice.catalog.js';
import { TUTORS } from './tutors.catalog.js';

export interface CatalogRoutesOptions {
  verifier: TokenVerifier;
}

/** Read-only catalogue. Authenticated, private cache allowed (content is not user-specific). */
export const catalogRoutes: FastifyPluginAsync<CatalogRoutesOptions> = async (app, { verifier }) => {
  app.addHook('preHandler', authenticate(verifier));

  app.get('/tutors', async (_request, reply) => {
    reply.header('cache-control', 'private, max-age=300');
    return { tutors: TUTORS };
  });

  app.get('/practice/categories', async (_request, reply) => {
    reply.header('cache-control', 'private, max-age=300');
    return { categories: PRACTICE_CATEGORIES };
  });
};
