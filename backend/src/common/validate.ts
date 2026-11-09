import type { FastifyReply, FastifyRequest, preHandlerAsyncHookHandler } from 'fastify';
import type { z } from 'zod';
import { validationError } from './errors.js';

export interface RequestSchemas {
  body?: z.ZodType;
  query?: z.ZodType;
  params?: z.ZodType;
}

/**
 * Request validation middleware (Fastify preHandler).
 *
 * Validates `body`, `query` and `params` with Zod and replaces them with the parsed
 * output, so handlers only ever see validated, typed data. Use `.strict()` objects
 * to reject unknown fields on writes.
 *
 * ```ts
 * app.post('/things', { preHandler: validate({ body: CreateThing }) }, handler)
 * ```
 */
export function validate(schemas: RequestSchemas): preHandlerAsyncHookHandler {
  return async function validateRequest(request: FastifyRequest, _reply: FastifyReply) {
    const details: { path: string; message: string }[] = [];
    for (const part of ['params', 'query', 'body'] as const) {
      const schema = schemas[part];
      if (!schema) continue;
      const result = schema.safeParse(request[part]);
      if (result.success) {
        (request as unknown as Record<string, unknown>)[part] = result.data;
      } else {
        for (const issue of result.error.issues) {
          details.push({ path: [part, ...issue.path].join('.'), message: issue.message });
        }
      }
    }
    if (details.length) throw validationError(details);
  };
}
