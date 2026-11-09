import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { validate } from '../../common/validate.js';
import { authenticate } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import type { CatalogService } from './catalog.service.js';
import { CONTENT_LOCALES, DEFAULT_CONTENT_LOCALE } from './content-variants.js';

export interface CatalogRoutesOptions {
  verifier: TokenVerifier;
  catalog: CatalogService;
}

const CatalogQuery = z
  .object({ locale: z.enum(CONTENT_LOCALES).default(DEFAULT_CONTENT_LOCALE) })
  .strict();

/**
 * Read-only catalogue. Authenticated, private cache allowed (content is not user-specific).
 * Only published (human-reviewed in production) scenarios are returned, each with the
 * ids of tutors compatible with it.
 */
export const catalogRoutes: FastifyPluginAsync<CatalogRoutesOptions> = async (app, { verifier, catalog }) => {
  app.addHook('preHandler', authenticate(verifier));

  app.get('/tutors', async (_request, reply) => {
    reply.header('cache-control', 'private, max-age=300');
    return { tutors: catalog.tutors };
  });

  app.get<{ Querystring: z.infer<typeof CatalogQuery> }>(
    '/practice/categories',
    { preHandler: validate({ query: CatalogQuery }) },
    async (request, reply) => {
      reply.header('cache-control', 'private, max-age=300');
      return { locale: request.query.locale, categories: catalog.publishedCategories(request.query.locale) };
    },
  );
};
