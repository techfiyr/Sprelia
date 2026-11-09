import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

/** Static site published by Netlify (netlify.toml `publish`): landing page, policy drafts, consent. */
const ROOT = fileURLToPath(new URL('../netlify/public', import.meta.url));
const TOML = readFileSync(fileURLToPath(new URL('../../netlify.toml', import.meta.url)), 'utf8');

const walk = (dir: string): string[] =>
  readdirSync(dir).flatMap((f) => (statSync(join(dir, f)).isDirectory() ? walk(join(dir, f)) : [join(dir, f)]));
const files = walk(ROOT);
const pages = files.filter((f) => f.endsWith('.html'));
const read = (rel: string) => readFileSync(join(ROOT, rel), 'utf8');
const POLICIES = ['privacy', 'terms', 'ai-disclaimer', 'content-policy', 'cookies'];

describe('static site', () => {
  it('has the landing page, every policy draft, cookies page, 404 and robots.txt', () => {
    for (const rel of ['index.html', '404.html', 'robots.txt', 'assets/site.css', 'assets/consent.js', ...POLICIES.map((p) => `${p}/index.html`)]) {
      expect(existsSync(join(ROOT, rel)), rel).toBe(true);
    }
  });

  it.each(pages.map((p) => relative(ROOT, p)))('%s: language, viewport, title, landmarks, one h1, skip link', (rel) => {
    const html = read(rel);
    expect(html).toMatch(/^<!doctype html>/i);
    expect(html).toMatch(/<html lang="en" dir="ltr">/);
    expect(html).toContain('<meta name="viewport" content="width=device-width, initial-scale=1">');
    expect(html).toMatch(/<title>[^<]+<\/title>/);
    expect(html).toMatch(/<meta name="description" content="[^"]+">/);
    expect(html.match(/<h1[\s>]/g)?.length).toBe(1);
    expect(html).toContain('<a class="skip-link" href="#main">');
    expect(html).toContain('<main id="main"');
    expect(html).toContain('<nav class="site-nav" aria-label="Main">');
    expect(html).toContain('<footer class="site-footer">');
    expect(html).toContain('data-consent-open');
  });

  it('every internal link resolves to a published file', () => {
    for (const page of pages) {
      for (const [, href] of read(relative(ROOT, page)).matchAll(/href="([^"#]+)"/g)) {
        if (/^(https?:|mailto:)/.test(href!)) continue;
        const target = href!.endsWith('/') ? join(ROOT, href!, 'index.html') : join(ROOT, href!);
        expect(existsSync(target), `${relative(ROOT, page)} → ${href}`).toBe(true);
      }
    }
  });

  it('loads first-party resources only: no external URLs, inline scripts, inline styles or event handlers', () => {
    for (const page of pages) {
      const html = read(relative(ROOT, page));
      expect(html, page).not.toMatch(/(src|href)="(https?:)?\/\//);
      expect(html, page).not.toMatch(/<script(?![^>]*\bsrc=)[^>]*>/);
      expect(html, page).not.toMatch(/\sstyle="/);
      expect(html, page).not.toMatch(/\son[a-z]+="/);
    }
  });

  it('contains no analytics, advertising or tracking code', () => {
    const code = files.filter((f) => /\.(html|js|css)$/.test(f)).map((f) => readFileSync(f, 'utf8')).join('\n');
    for (const tracker of ['gtag(', 'googletagmanager', 'google-analytics', 'fbq(', 'hotjar', 'clarity.ms', 'mixpanel', 'segment.com', 'adsbygoogle', 'document.cookie']) {
      expect(code, tracker).not.toContain(tracker);
    }
  });

  it('policy drafts are marked as drafts, not indexed, and keep unknowable items as review placeholders', () => {
    for (const p of POLICIES) {
      const html = read(`${p}/index.html`);
      expect(html, p).toContain('<meta name="robots" content="noindex">');
      expect(html, p).toContain('<strong>Draft for review.</strong>');
      expect(html, p).toContain('[Review: effective date]');
    }
    expect(read('privacy/index.html')).toContain('[Review: legal name and registered address of the operator]');
    expect(read('privacy/index.html')).toContain('[Review: privacy contact email]');
    expect(read('terms/index.html')).toContain('[Review: governing law, venue and dispute resolution]');
  });

  it('marks unapproved policy choices as pending instead of asserting them', () => {
    const privacy = read('privacy/index.html');
    expect(privacy).toMatch(/Pending decision:<\/strong> Hermione currently deletes/);
    expect(privacy).toMatch(/Pending decision:<\/strong> how long transcripts are kept/);
    expect(privacy).toMatch(/Pending decision:<\/strong> how age is confirmed/);
    expect(read('terms/index.html')).toMatch(/Pending decision:<\/strong> Premium prices, trial offers, renewal terms and the refund policy/);
  });

  it('is not indexed before launch (robots.txt) and never claims the brand is registered', () => {
    expect(read('robots.txt')).toMatch(/User-agent: \*\s+Disallow: \//);
    for (const page of pages) expect(read(relative(ROOT, page))).not.toMatch(/®|™|trademark of/i);
  });
});

describe('netlify.toml', () => {
  it('publishes only the static folder and routes functions from the backend base', () => {
    expect(TOML).toMatch(/base = "backend"/);
    expect(TOML).toMatch(/publish = "netlify\/public"/);
    expect(TOML).toMatch(/directory = "netlify\/functions"/);
  });
  it('sends a first-party-only Content-Security-Policy for the site', () => {
    expect(TOML).toMatch(/Content-Security-Policy = "default-src 'self'; script-src 'self'; style-src 'self';/);
    expect(TOML).toMatch(/frame-ancestors 'none'/);
  });
  it('contains no secrets or environment values', () => {
    expect(TOML).not.toMatch(/FIREBASE_SERVICE_ACCOUNT_JSON\s*=|private_key|BEGIN/);
  });
});

describe('consent store (assets/consent.js)', () => {
  type Store = {
    get(): { version: number; decidedAt: string; choices: Record<string, boolean> } | null;
    needsDecision(): boolean;
    has(c: string): boolean;
    rejectAll(): unknown;
    acceptAll(): unknown;
    save(c: Record<string, unknown>): unknown;
  };
  type ConsentModule = {
    CONSENT_VERSION: number;
    STORAGE_KEY: string;
    createConsentStore(storage: unknown, now?: () => Date): Store;
    parseRecord(raw: unknown): unknown;
  };
  const load = async (): Promise<ConsentModule> => import(new URL('../netlify/public/assets/consent.js', import.meta.url).href);
  const memoryStorage = () => {
    const data = new Map<string, string>();
    return { data, getItem: (k: string) => data.get(k) ?? null, setItem: (k: string, v: string) => void data.set(k, v) };
  };
  const NOW = () => new Date('2026-11-09T10:00:00Z');

  it('nothing optional is allowed before a decision; necessary is always allowed', async () => {
    const { createConsentStore } = await load();
    const store = createConsentStore(memoryStorage(), NOW);
    expect(store.needsDecision()).toBe(true);
    expect(store.has('analytics')).toBe(false);
    expect(store.has('marketing')).toBe(false);
    expect(store.has('necessary')).toBe(true);
  });

  it('reject all, accept all and custom choices are stored as a versioned record', async () => {
    const { createConsentStore, STORAGE_KEY, CONSENT_VERSION } = await load();
    const storage = memoryStorage();
    const store = createConsentStore(storage, NOW);

    store.rejectAll();
    expect(JSON.parse(storage.data.get(STORAGE_KEY)!)).toEqual({
      version: CONSENT_VERSION,
      decidedAt: '2026-11-09T10:00:00.000Z',
      choices: { analytics: false, marketing: false },
    });
    expect(store.needsDecision()).toBe(false);

    store.acceptAll();
    expect(store.has('analytics') && store.has('marketing')).toBe(true);

    store.save({ analytics: true, marketing: 'yes', tracking: true });
    expect(store.get()!.choices).toEqual({ analytics: true, marketing: false });
  });

  it('ignores old versions, tampered or corrupted records (asks again)', async () => {
    const { createConsentStore, parseRecord, STORAGE_KEY } = await load();
    const storage = memoryStorage();
    storage.setItem(STORAGE_KEY, JSON.stringify({ version: 0, decidedAt: '2026-01-01T00:00:00Z', choices: { analytics: true, marketing: true } }));
    expect(createConsentStore(storage).needsDecision()).toBe(true);
    for (const raw of ['{not json', 'null', '{"version":1,"decidedAt":"x","choices":{}}', '{"version":1,"decidedAt":"2026-01-01T00:00:00Z","choices":{"analytics":"yes","marketing":false}}']) {
      expect(parseRecord(raw), raw).toBeNull();
    }
  });

  it('works without storage (blocked or private mode): choice kept in memory only', async () => {
    const { createConsentStore } = await load();
    const throwing = {
      getItem: () => {
        throw new Error('blocked');
      },
      setItem: () => {
        throw new Error('blocked');
      },
    };
    const store = createConsentStore(throwing, NOW);
    store.acceptAll();
    expect(store.has('analytics')).toBe(true);
    expect(createConsentStore(null).needsDecision()).toBe(true);
  });
});
