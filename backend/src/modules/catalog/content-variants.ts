import type { PracticeCategory, Scenario } from './practice.catalog.js';

/**
 * English content variants. The base catalogue is American English (`en-US`, owner
 * decision for the initial release). A future British English release adds text
 * overrides here; ids, levels, tutors and premium flags never vary by locale.
 *
 * Example (not active):
 *   'en-GB': { scenarios: { 'food-restaurants': { vocabulary: [..., 'the bill, please', ...] } } }
 */
export const CONTENT_LOCALES = ['en-US', 'en-GB'] as const;
export type ContentLocale = (typeof CONTENT_LOCALES)[number];
export const DEFAULT_CONTENT_LOCALE: ContentLocale = 'en-US';

type ScenarioText = Partial<Pick<Scenario, 'title' | 'description' | 'objectives' | 'vocabulary'>>;
type CategoryText = Partial<Pick<PracticeCategory, 'title' | 'description'>>;

interface Overlay {
  categories?: Record<string, CategoryText>;
  scenarios?: Record<string, ScenarioText>;
}

const OVERLAYS: Partial<Record<ContentLocale, Overlay>> = {
  // 'en-GB': {}  ← add British English overrides here when that variant is approved.
};

/** Applies the locale's text overrides (falls back to en-US for anything missing). */
export function localize(categories: readonly PracticeCategory[], locale: ContentLocale): PracticeCategory[] {
  const overlay = OVERLAYS[locale] ?? {};
  return categories.map((c) => ({
    ...c,
    ...(overlay.categories?.[c.id] ?? {}),
    scenarios: c.scenarios.map((s) => ({ ...s, ...(overlay.scenarios?.[s.id] ?? {}) })),
  }));
}
