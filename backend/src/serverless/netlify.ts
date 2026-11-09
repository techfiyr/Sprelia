import { isIP } from 'node:net';
import type { FastifyInstance, InjectOptions } from 'fastify';
import { ConfigError, type AppConfig } from '../config/env.js';

/**
 * Netlify Functions adapter (owner hosting decision 2026-11-09).
 *
 * Bridges a Netlify Function (modern API: `(req: Request, context) => Response`) to the existing
 * Fastify app through `app.inject()`, so routes, validation, auth, error handling and headers are
 * exactly the same as on a long-running server.
 *
 * Client IP: taken ONLY from Netlify's `context.ip` (documented as "the client IP address") and
 * passed as the connection's remote address. Forwarding headers sent by the caller are never
 * trusted, so the app must run with TRUST_PROXY_HOPS=0 (enforced at startup).
 *
 * Rate limiting: @fastify/rate-limit keeps counters in memory, so on serverless they are
 * PER FUNCTION INSTANCE, not global. They slow down a single noisy client on a warm instance
 * but are not a distributed limit.
 */

/** The subset of Netlify's `Context` this adapter uses (see docs: build/functions/api). */
export interface NetlifyContextLike {
  ip?: string;
  requestId?: string;
}

export type NetlifyHandler = (req: Request, context?: NetlifyContextLike) => Promise<Response>;

/** Headers that describe one hop or the framing of a message; never copied between the two. */
const HOP_BY_HOP = new Set([
  'connection',
  'keep-alive',
  'proxy-connection',
  'transfer-encoding',
  'upgrade',
  'te',
  'trailer',
  'content-length',
]);

const METHODS = new Set(['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']);
const SAFE_REQUEST_ID = /^[A-Za-z0-9._-]{8,64}$/;

const errorResponse = (status: number, code: string, message: string) =>
  new Response(JSON.stringify({ error: { code, message } }), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

const unavailable = () =>
  errorResponse(503, 'SERVICE_UNAVAILABLE', 'Service temporarily unavailable. Please try again.');

/**
 * Netlify-specific configuration rules, checked before the app is built:
 * the client IP comes from `context.ip`, so caller-supplied forwarding headers must never be
 * trusted (TRUST_PROXY_HOPS=0).
 */
export function assertNetlifyConfig(config: Pick<AppConfig, 'trustProxyHops'>): void {
  if (config.trustProxyHops !== 0) {
    throw new ConfigError(['TRUST_PROXY_HOPS: must be 0 on Netlify (the client IP comes from context.ip)']);
  }
}

export interface NetlifyHandlerOptions {
  /** Where startup failures are reported (default: console.error). Never receives secret values. */
  reportStartupError?: (message: string) => void;
}

/**
 * Creates the Netlify handler. `createApp` runs once per function instance (cold start) and its
 * result is reused while the instance stays warm; a failed start is retried on the next request.
 */
export function createNetlifyHandler(
  createApp: () => Promise<FastifyInstance>,
  { reportStartupError = (m) => console.error(m) }: NetlifyHandlerOptions = {},
): NetlifyHandler {
  let appPromise: Promise<FastifyInstance> | undefined;

  const getApp = () => {
    appPromise ??= createApp().then(async (app) => {
      await app.ready();
      return app;
    });
    appPromise.catch(() => {
      appPromise = undefined;
    });
    return appPromise;
  };

  return async function netlifyHandler(req: Request, context?: NetlifyContextLike): Promise<Response> {
    let app: FastifyInstance;
    try {
      app = await getApp();
    } catch (err) {
      // ConfigError lists invalid keys only; anything else is reduced to its type name.
      reportStartupError(
        err instanceof ConfigError ? err.message : `API startup failed (${err instanceof Error ? err.name : 'unknown error'})`,
      );
      return unavailable();
    }

    const method = req.method.toUpperCase();
    if (!METHODS.has(method)) return errorResponse(405, 'BAD_REQUEST', 'Method not allowed.');

    const url = new URL(req.url);
    const headers: Record<string, string> = {};
    req.headers.forEach((value, key) => {
      if (!HOP_BY_HOP.has(key)) headers[key] = value;
    });
    if (!headers['x-request-id'] && context?.requestId && SAFE_REQUEST_ID.test(context.requestId)) {
      headers['x-request-id'] = context.requestId;
    }

    const body = method === 'GET' || method === 'HEAD' ? undefined : Buffer.from(await req.arrayBuffer());
    const remoteAddress = context?.ip && isIP(context.ip) ? context.ip : undefined;

    const res = await app.inject({
      method: method as InjectOptions['method'],
      url: url.pathname + url.search,
      headers,
      payload: body && body.length > 0 ? body : undefined,
      remoteAddress,
    } as InjectOptions);

    const out = new Headers();
    for (const [key, value] of Object.entries(res.headers)) {
      if (value === undefined || HOP_BY_HOP.has(key)) continue;
      if (Array.isArray(value)) for (const v of value) out.append(key, String(v));
      else out.set(key, String(value));
    }
    const noBody = method === 'HEAD' || res.statusCode === 204 || res.statusCode === 304;
    return new Response(noBody ? null : new Uint8Array(res.rawPayload), { status: res.statusCode, headers: out });
  };
}
