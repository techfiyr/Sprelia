import { describe, expect, it } from 'vitest';
import { ConfigError } from '../src/config/env.js';
import type { IdentityAdmin } from '../src/modules/account/identity-admin.js';
import { assertNetlifyConfig, createNetlifyHandler } from '../src/serverless/netlify.js';
import { makeApp, testConfig, TEST_USER, VALID_TOKEN } from './helpers.js';

const BASE = 'https://sprelia-api.netlify.app';
const auth = { authorization: `Bearer ${VALID_TOKEN}` };

class FakeIdentity implements IdentityAdmin {
  deleted: string[] = [];
  async deleteUser(uid: string) {
    this.deleted.push(uid);
  }
}

/** Netlify handler around the real app with fake Firebase dependencies. */
async function handlerWith(opts: Parameters<typeof makeApp>[0] = {}) {
  const app = await makeApp({
    ...opts,
    register: (a) => {
      a.get('/api/v1/__test/ip', async (req) => ({ ip: req.ip }));
      opts.register?.(a);
    },
  });
  return createNetlifyHandler(async () => app);
}

describe('Netlify Functions adapter', () => {
  it('serves the existing routes unchanged (health, JSON, security headers)', async () => {
    const handler = await handlerWith();
    const res = await handler(new Request(`${BASE}/api/v1/health`), { ip: '203.0.113.7', requestId: '01HZXREQUEST123' });
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('application/json');
    expect(res.headers.get('x-request-id')).toBe('01HZXREQUEST123');
    expect(res.headers.get('x-content-type-options')).toBe('nosniff');
    expect(await res.json()).toMatchObject({ status: 'ok' });
  });

  it('passes the Authorization header, JSON bodies and query strings through', async () => {
    const handler = await handlerWith();
    const me = await handler(new Request(`${BASE}/api/v1/me`, { headers: auth }));
    expect(me.status).toBe(200);
    expect((await me.json()).uid).toBe(TEST_USER.uid);

    const created = await handler(
      new Request(`${BASE}/api/v1/me/profile`, {
        method: 'POST',
        headers: { ...auth, 'content-type': 'application/json' },
        body: JSON.stringify({ timezone: 'Asia/Dhaka' }),
      }),
    );
    expect(created.status).toBe(201);
    expect((await created.json()).profile.timezone).toBe('Asia/Dhaka');

    const gb = await handler(new Request(`${BASE}/api/v1/practice/categories?locale=en-GB`, { headers: auth }));
    expect((await gb.json()).locale).toBe('en-GB');
    const bad = await handler(new Request(`${BASE}/api/v1/practice/categories?locale=xx`, { headers: auth }));
    expect(bad.status).toBe(400);
  });

  it('requires authentication exactly as before', async () => {
    const handler = await handlerWith();
    const res = await handler(new Request(`${BASE}/api/v1/me`));
    expect(res.status).toBe(401);
    expect((await res.json()).error.code).toBe('UNAUTHENTICATED');
  });

  it('uses only context.ip as the client IP; spoofed forwarding headers are ignored', async () => {
    const handler = await handlerWith();
    const spoofed = { 'x-forwarded-for': '198.51.100.66', 'x-real-ip': '198.51.100.66', 'x-nf-client-connection-ip': '198.51.100.66' };
    const res = await handler(new Request(`${BASE}/api/v1/__test/ip`, { headers: spoofed }), { ip: '203.0.113.7' });
    expect((await res.json()).ip).toBe('203.0.113.7');
    const invalid = await handler(new Request(`${BASE}/api/v1/__test/ip`, { headers: spoofed }), { ip: 'not-an-ip' });
    expect((await invalid.json()).ip).not.toBe('198.51.100.66');
  });

  it('returns an empty body for 204 and HEAD responses', async () => {
    const identity = new FakeIdentity();
    const handler = await handlerWith({ identity, now: () => new Date((TEST_USER.authTime + 60) * 1000) });
    const del = await handler(new Request(`${BASE}/api/v1/me`, { method: 'DELETE', headers: auth }));
    expect(del.status).toBe(204);
    expect(await del.text()).toBe('');
    expect(identity.deleted).toEqual([TEST_USER.uid]);

    const head = await handler(new Request(`${BASE}/api/v1/health`, { method: 'HEAD' }));
    expect(head.status).toBe(200);
    expect(await head.text()).toBe('');
  });

  it('keeps the app error model (404, 413) and rejects unsupported methods', async () => {
    const handler = await handlerWith();
    const missing = await handler(new Request(`${BASE}/api/v1/nope`, { headers: auth }));
    expect(missing.status).toBe(404);
    expect((await missing.json()).error.code).toBe('NOT_FOUND');

    const big = await handler(
      new Request(`${BASE}/api/v1/me/profile`, {
        method: 'POST',
        headers: { ...auth, 'content-type': 'application/json' },
        body: JSON.stringify({ timezone: 'x'.repeat(70 * 1024) }),
      }),
    );
    expect(big.status).toBe(413);

    const propfind = await handler(new Request(`${BASE}/api/v1/health`, { method: 'PROPFIND' }));
    expect(propfind.status).toBe(405);
  });

  it('builds the app once per instance and reuses it while warm', async () => {
    const app = await makeApp();
    let builds = 0;
    const handler = createNetlifyHandler(async () => {
      builds++;
      return app;
    });
    await handler(new Request(`${BASE}/api/v1/health`));
    await handler(new Request(`${BASE}/api/v1/health`));
    expect(builds).toBe(1);
  });

  it('startup failures return a generic 503, report key names only, and retry on the next request', async () => {
    const reported: string[] = [];
    const app = await makeApp();
    let attempt = 0;
    const handler = createNetlifyHandler(
      async () => {
        attempt++;
        if (attempt === 1) throw new ConfigError(['FIREBASE_SERVICE_ACCOUNT_JSON: must be a JSON object']);
        if (attempt === 2) throw new Error('secret-value-should-not-leak');
        return app;
      },
      { reportStartupError: (m) => reported.push(m) },
    );
    const first = await handler(new Request(`${BASE}/api/v1/health`));
    expect(first.status).toBe(503);
    expect(await first.json()).toEqual({
      error: { code: 'SERVICE_UNAVAILABLE', message: 'Service temporarily unavailable. Please try again.' },
    });
    const second = await handler(new Request(`${BASE}/api/v1/health`));
    expect(second.status).toBe(503);
    expect((await handler(new Request(`${BASE}/api/v1/health`))).status).toBe(200);

    expect(reported[0]).toContain('FIREBASE_SERVICE_ACCOUNT_JSON');
    expect(reported[1]).toBe('API startup failed (Error)');
    expect(reported.join('\n')).not.toContain('secret-value-should-not-leak');
  });
});

describe('assertNetlifyConfig', () => {
  it('requires TRUST_PROXY_HOPS=0 (client IP comes from context.ip)', () => {
    expect(() => assertNetlifyConfig(testConfig())).not.toThrow();
    expect(() => assertNetlifyConfig(testConfig({ TRUST_PROXY_HOPS: '1' }))).toThrowError(/TRUST_PROXY_HOPS/);
  });
});
