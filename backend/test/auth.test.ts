import { afterEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { extractBearerToken } from '../src/modules/auth/authenticate.js';
import { FakeVerifier, LogCapture, makeApp, OUTAGE_TOKEN, REVOKED_TOKEN, VALID_TOKEN } from './helpers.js';

const ME = '/api/v1/me';

describe('GET /api/v1/me', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('rejects requests without an Authorization header', async () => {
    const verifier = new FakeVerifier();
    app = await makeApp({ verifier });
    const res = await app.inject({ method: 'GET', url: ME });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('UNAUTHENTICATED');
    expect(verifier.calls).toHaveLength(0);
  });

  it.each([
    ['wrong scheme', `Basic ${VALID_TOKEN}`],
    ['lowercase scheme', `bearer ${VALID_TOKEN}`],
    ['missing token', 'Bearer '],
    ['scheme only', 'Bearer'],
    ['two tokens', `Bearer ${VALID_TOKEN} ${VALID_TOKEN}`],
  ])('rejects a malformed header (%s) without calling the verifier', async (_name, header) => {
    const verifier = new FakeVerifier();
    app = await makeApp({ verifier });
    const res = await app.inject({ method: 'GET', url: ME, headers: { authorization: header } });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('UNAUTHENTICATED');
    expect(verifier.calls).toHaveLength(0);
  });

  it.each([
    ['not a JWT', 'Bearer not-a-jwt'],
    ['oversized token', `Bearer ${'a'.repeat(3000)}.${'b'.repeat(1000)}.${'c'.repeat(200)}`],
  ])('rejects an invalid token shape (%s) without calling the verifier', async (_name, header) => {
    const verifier = new FakeVerifier();
    app = await makeApp({ verifier });
    const res = await app.inject({ method: 'GET', url: ME, headers: { authorization: header } });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('INVALID_TOKEN');
    expect(verifier.calls).toHaveLength(0);
  });

  it('rejects a token the verifier refuses (expired / revoked / forged)', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: ME, headers: { authorization: `Bearer ${REVOKED_TOKEN}` } });
    expect(res.statusCode).toBe(401);
    const body = res.json();
    expect(body.error.code).toBe('INVALID_TOKEN');
    // The underlying reason is logged, not returned.
    expect(JSON.stringify(body)).not.toContain('revoked');
  });

  it('returns 503 without internal details when verification is unavailable', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: ME, headers: { authorization: `Bearer ${OUTAGE_TOKEN}` } });
    expect(res.statusCode).toBe(503);
    expect(res.json().error.code).toBe('SERVICE_UNAVAILABLE');
    expect(res.body).not.toContain('ECONNRESET');
  });

  it('returns the verified identity for a valid token', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: ME, headers: { authorization: `Bearer ${VALID_TOKEN}` } });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      uid: 'user-123',
      email: 'learner@example.com',
      emailVerified: true,
      signInProvider: 'password',
    });
    expect(res.headers['cache-control']).toBe('private, no-store');
  });

  it('ignores identity claims supplied by the client', async () => {
    app = await makeApp();
    const res = await app.inject({
      method: 'GET',
      url: `${ME}?uid=attacker`,
      headers: { authorization: `Bearer ${VALID_TOKEN}`, 'x-dev-user-id': 'attacker', 'x-user-id': 'attacker' },
    });
    expect(res.json().uid).toBe('user-123');
  });

  it('does not accept writes to the user record', async () => {
    app = await makeApp();
    for (const method of ['POST', 'PUT', 'PATCH', 'DELETE'] as const) {
      const res = await app.inject({
        method,
        url: ME,
        headers: { authorization: `Bearer ${VALID_TOKEN}` },
        payload: { uid: 'other', plan: 'premium' },
      });
      expect(res.statusCode).toBe(404);
    }
  });

  it('never writes the bearer token to the logs', async () => {
    const logs = new LogCapture();
    app = await makeApp({ logs });
    await app.inject({ method: 'GET', url: ME, headers: { authorization: `Bearer ${VALID_TOKEN}` } });
    await app.inject({ method: 'GET', url: ME, headers: { authorization: `Bearer ${REVOKED_TOKEN}` } });
    expect(logs.lines.length).toBeGreaterThan(0);
    expect(logs.text).not.toContain(VALID_TOKEN);
    expect(logs.text).not.toContain(REVOKED_TOKEN);
    expect(logs.text).toContain('"severity":"INFO"');
  });
});

describe('extractBearerToken', () => {
  it('returns the token for a well-formed header', () => {
    expect(extractBearerToken(`Bearer ${VALID_TOKEN}`)).toBe(VALID_TOKEN);
  });
  it('throws for a missing header', () => {
    expect(() => extractBearerToken(undefined)).toThrowError(/Authentication required/);
  });
});
