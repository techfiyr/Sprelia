import { afterEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { CatalogError, CatalogService } from '../src/modules/catalog/catalog.service.js';
import { cefrRank, isTutorCompatible, validateCatalog } from '../src/modules/catalog/compatibility.js';
import { PRACTICE_CATEGORIES, type PracticeCategory } from '../src/modules/catalog/practice.catalog.js';
import { TUTORS } from '../src/modules/catalog/tutors.catalog.js';
import { makeApp, testConfig, VALID_TOKEN } from './helpers.js';

const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1'] as const;
const all = PRACTICE_CATEGORIES.flatMap((c) => c.scenarios.map((s) => ({ c, s })));
const covers = (s: { cefr: { min: string; max: string } }, l: (typeof LEVELS)[number]) =>
  cefrRank(s.cefr.min as never) <= cefrRank(l) && cefrRank(l) <= cefrRank(s.cefr.max as never);

describe('catalogue policy (owner decisions 2026-11-09)', () => {
  it('is valid: every suggested tutor supports the category and covers the scenario range', () => {
    expect(validateCatalog(PRACTICE_CATEGORIES, TUTORS)).toEqual([]);
  });

  it('study abroad is not assigned to Emma, and networking uses Alex only because Alex supports Social', () => {
    const study = all.find((x) => x.s.id === 'study-abroad')!;
    expect(study.s.suggestedTutorId).not.toBe('emma');
    const sofia = TUTORS.find((t) => t.id === 'sofia')!;
    expect(sofia.categoryIds).not.toContain('academic'); // Sofia not eligible: category unsupported
    const networking = all.find((x) => x.s.id === 'networking')!;
    const alex = TUTORS.find((t) => t.id === 'alex')!;
    expect(networking.s.suggestedTutorId).toBe('alex');
    expect(alex.categoryIds).toContain('social');
    expect(isTutorCompatible(alex, 'social', networking.s)).toBe(true);
  });

  it('has A1 scenarios in Professional and Academic, and at least 3 B2 Travel scenarios', () => {
    for (const cat of ['professional', 'academic']) {
      expect(all.some((x) => x.c.id === cat && covers(x.s, 'A1') && !x.s.premium)).toBe(true);
    }
    expect(all.filter((x) => x.c.id === 'travel' && covers(x.s, 'B2')).length).toBeGreaterThanOrEqual(3);
  });

  it('has about five premium scenarios, and free coverage remains in every category', () => {
    const premium = all.filter((x) => x.s.premium);
    expect(premium.length).toBe(5);
    for (const c of PRACTICE_CATEGORIES) {
      const free = c.scenarios.filter((s) => !s.premium);
      expect(free.length, c.id).toBeGreaterThanOrEqual(3);
      // Every level the category serves at all is still served for free.
      for (const l of LEVELS) {
        if (c.scenarios.some((s) => covers(s, l))) expect(free.some((s) => covers(s, l)), `${c.id} ${l}`).toBe(true);
      }
    }
  });

  it('uses only 5, 10 and 15 minute durations', () => {
    expect(new Set(all.map((x) => x.s.estimatedMinutes))).toEqual(new Set([5, 10]));
  });

  it('uses American English spelling', () => {
    const text = JSON.stringify([PRACTICE_CATEGORIES, TUTORS]);
    expect(text).not.toMatch(/practis|analys|colour|favour|organis|recognis|centre|travell|\benrol\b|programme|behaviour|the bill\b|in a shop|\bcheck-out\b/i);
  });

  it('rejects an incompatible catalogue at startup', () => {
    const broken: PracticeCategory[] = [
      { ...PRACTICE_CATEGORIES[2]!, scenarios: PRACTICE_CATEGORIES[2]!.scenarios.map((s) => (s.id === 'study-abroad' ? { ...s, suggestedTutorId: 'emma' } : s)) },
    ];
    expect(() => new CatalogService({ includeDrafts: true }, { categories: broken })).toThrowError(CatalogError);
    expect(validateCatalog(broken, TUTORS).join()).toMatch(/study-abroad: suggested tutor emma/);
  });

  it('publishes only human-reviewed scenarios when drafts are excluded (production)', () => {
    expect(new CatalogService({ includeDrafts: false }).publishedCategories()).toEqual([]);
    const reviewed: PracticeCategory[] = [
      {
        ...PRACTICE_CATEGORIES[0]!,
        scenarios: PRACTICE_CATEGORIES[0]!.scenarios.map((s, i) =>
          i === 0 ? { ...s, reviewStatus: 'approved' as const, reviewedBy: 'Reviewer', reviewedAt: '2026-11-10' } : s,
        ),
      },
    ];
    const published = new CatalogService({ includeDrafts: false }, { categories: reviewed }).publishedCategories();
    expect(published.flatMap((c) => c.scenarios.map((s) => s.id))).toEqual(['introductions']);
  });

  it('an approved scenario must name its reviewer and date', () => {
    const bad: PracticeCategory[] = [
      { ...PRACTICE_CATEGORIES[0]!, scenarios: [{ ...PRACTICE_CATEGORIES[0]!.scenarios[0]!, reviewStatus: 'approved' }] },
    ];
    expect(validateCatalog(bad, TUTORS).join()).toMatch(/reviewedBy and reviewedAt/);
  });
});

describe('GET /api/v1/practice/categories', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());
  const auth = { authorization: `Bearer ${VALID_TOKEN}` };

  it('returns compatible tutor ids and premium flags, in en-US by default', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/practice/categories', headers: auth });
    const body = res.json();
    expect(body.locale).toBe('en-US');
    const job = body.categories.flatMap((c: { scenarios: unknown[] }) => c.scenarios).find((s: { id: string }) => s.id === 'job-interviews');
    expect(job.compatibleTutorIds).toEqual(['alex']);
    expect(job.premium).toBe(false);
  });

  it('accepts en-GB (falls back to en-US text until a variant exists) and rejects unknown locales', async () => {
    app = await makeApp();
    const gb = await app.inject({ method: 'GET', url: '/api/v1/practice/categories?locale=en-GB', headers: auth });
    expect(gb.statusCode).toBe(200);
    expect(gb.json().locale).toBe('en-GB');
    const bad = await app.inject({ method: 'GET', url: '/api/v1/practice/categories?locale=fr', headers: auth });
    expect(bad.statusCode).toBe(400);
  });

  it('serves no unreviewed scenarios when drafts are disabled', async () => {
    app = await makeApp({ config: testConfig({ CATALOG_INCLUDE_DRAFTS: 'false' }) });
    const res = await app.inject({ method: 'GET', url: '/api/v1/practice/categories', headers: auth });
    expect(res.json().categories).toEqual([]);
  });
});
