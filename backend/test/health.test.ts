import { afterEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { makeApp } from './helpers.js';

describe('GET /api/v1/health', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('returns ok without authentication', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ status: 'ok' });
    expect(res.headers['cache-control']).toBe('no-store');
  });

  it('exposes no infrastructure details', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/health' });
    expect(Object.keys(res.json())).toEqual(['status']);
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['server']).toBeUndefined();
    expect(res.body).not.toMatch(/demo-sprelia|test|node|version/i);
  });

  it('sets security headers and a request id', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/health' });
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
  });

  it('echoes a safe caller request id but replaces an unsafe one', async () => {
    app = await makeApp();
    const safe = await app.inject({ method: 'GET', url: '/api/v1/health', headers: { 'x-request-id': 'trace-12345678' } });
    expect(safe.headers['x-request-id']).toBe('trace-12345678');
    const unsafe = await app.inject({
      method: 'GET',
      url: '/api/v1/health',
      headers: { 'x-request-id': 'bad id\n{"injected":true}' },
    });
    expect(unsafe.headers['x-request-id']).not.toContain('injected');
  });
});

describe('unknown routes', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('returns a JSON 404 envelope', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/does-not-exist' });
    expect(res.statusCode).toBe(404);
    const body = res.json();
    expect(body.error.code).toBe('NOT_FOUND');
    expect(body.error.requestId).toBeTypeOf('string');
  });

  it('does not serve the unversioned prototype paths', async () => {
    app = await makeApp();
    expect((await app.inject({ method: 'GET', url: '/healthz' })).statusCode).toBe(404);
    expect((await app.inject({ method: 'GET', url: '/v1/usage/daily' })).statusCode).toBe(404);
  });
});
