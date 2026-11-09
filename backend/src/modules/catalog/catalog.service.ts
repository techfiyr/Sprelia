import { compatibleTutorIds, validateCatalog } from './compatibility.js';
import { DEFAULT_CONTENT_LOCALE, localize, type ContentLocale } from './content-variants.js';
import { PRACTICE_CATEGORIES, type PracticeCategory, type Scenario } from './practice.catalog.js';
import { TUTORS, type PublicTutor } from './tutors.catalog.js';

export type PublishedScenario = Scenario & { compatibleTutorIds: string[] };
export type PublishedCategory = Omit<PracticeCategory, 'scenarios'> & { scenarios: PublishedScenario[] };

export class CatalogError extends Error {
  constructor(public readonly problems: string[]) {
    super(`Invalid practice catalogue:\n  - ${problems.join('\n  - ')}`);
    this.name = 'CatalogError';
  }
}

/**
 * The published catalogue for one deployment.
 *
 * - Validates tutor/scenario compatibility at construction (throws CatalogError), so
 *   an incompatible catalogue can never be served.
 * - `includeDrafts: false` (forced in production) publishes only human-reviewed
 *   scenarios; categories without published scenarios are omitted.
 */
export class CatalogService {
  readonly tutors: readonly PublicTutor[];
  private readonly categories: readonly PracticeCategory[];

  constructor(
    private readonly options: { includeDrafts: boolean },
    source: { categories?: readonly PracticeCategory[]; tutors?: readonly PublicTutor[] } = {},
  ) {
    this.tutors = source.tutors ?? TUTORS;
    this.categories = source.categories ?? PRACTICE_CATEGORIES;
    const problems = validateCatalog(this.categories, this.tutors);
    if (problems.length) throw new CatalogError(problems);
  }

  /** Published categories with compatible tutor ids, in the requested English variant. */
  publishedCategories(locale: ContentLocale = DEFAULT_CONTENT_LOCALE): PublishedCategory[] {
    return localize(this.categories, locale)
      .map((c) => ({
        ...c,
        scenarios: c.scenarios
          .filter((s) => this.options.includeDrafts || s.reviewStatus === 'approved')
          .map((s) => ({ ...s, compatibleTutorIds: compatibleTutorIds(this.tutors, c.id, s) })),
      }))
      .filter((c) => c.scenarios.length > 0);
  }

  tutor(id: string): PublicTutor | undefined {
    return this.tutors.find((t) => t.id === id);
  }
}
