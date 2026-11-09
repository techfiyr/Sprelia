import { afterEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { validate } from '../src/common/validate.js';
import { makeApp } from './helpers.js';

const Body = z.object({ name: z.string().min(1).max(20), count: z.number().int().min(0) }).strict();
const Params = z.object({ id: z.string().regex(/^[a-z0-9]{3,10}$/) });

function registerProbe(app: FastifyInstance) {
  app.post<{ Params: z.infer<typeof Params>; Body: z.infer<typeof Body> }>(
    '/__probe/:id',
    { preHandler: validate({ params: Params, body: Body }) },
    async (request) => ({ id: request.params.id, ...request.body }),
  );
  app.get('/__boom', async () => {
    throw new Error('db password=hunter2 at 10.0.0.12');
  });
}

describe('validate() middleware', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('passes parsed data to the handler', async () => {
    app = await makeApp({ register: registerProbe });
    const res = await app.inject({ method: 'POST', url: '/__probe/abc', payload: { name: 'Emma', count: 2 } });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ id: 'abc', name: 'Emma', count: 2 });
  });

  it('returns 400 with field paths for invalid input', async () => {
    app = await makeApp({ register: registerProbe });
    const res = await app.inject({ method: 'POST', url: '/__probe/AB!', payload: { name: '', count: -1 } });
    expect(res.statusCode).toBe(400);
    const { error } = res.json();
    expect(error.code).toBe('VALIDATION_ERROR');
    const paths = error.details.map((d: { path: string }) => d.path);
    expect(paths).toEqual(expect.arrayContaining(['params.id', 'body.name', 'body.count']));
  });

  it('rejects unknown fields on strict schemas (no mass assignment)', async () => {
    app = await makeApp({ register: registerProbe });
    const res = await app.inject({
      method: 'POST',
      url: '/__probe/abc',
      payload: { name: 'Emma', count: 1, plan: 'premium' },
    });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_ERROR');
  });
});

describe('centralized error handling', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('hides internal error details', async () => {
    app = await makeApp({ register: registerProbe });
    const res = await app.inject({ method: 'GET', url: '/__boom' });
    expect(res.statusCode).toBe(500);
    expect(res.json().error.code).toBe('INTERNAL');
    expect(res.body).not.toMatch(/hunter2|10\.0\.0\.12|stack/);
  });

  it('maps malformed JSON to 400 BAD_REQUEST', async () => {
    app = await makeApp({ register: registerProbe });
    const res = await app.inject({
      method: 'POST',
      url: '/__probe/abc',
      headers: { 'content-type': 'application/json' },
      payload: '{"name":',
    });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('BAD_REQUEST');
  });

  it('maps oversized bodies to 413', async () => {
    app = await makeApp({ register: registerProbe });
    const res = await app.inject({
      method: 'POST',
      url: '/__probe/abc',
      payload: { name: 'x'.repeat(70 * 1024), count: 1 },
    });
    expect(res.statusCode).toBe(413);
    expect(res.json().error.code).toBe('PAYLOAD_TOO_LARGE');
  });

  it('rate limits per client and answers with 429', async () => {
    const { testConfig } = await import('./helpers.js');
    app = await makeApp({ config: testConfig({ RATE_LIMIT_PER_MINUTE: '2' }) });
    const hit = () => app.inject({ method: 'GET', url: '/api/v1/me' });
    await hit();
    await hit();
    const res = await hit();
    expect(res.statusCode).toBe(429);
    expect(res.json().error.code).toBe('RATE_LIMITED');
  });
});
