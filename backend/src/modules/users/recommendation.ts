import { cefrRank, isTutorCompatible, tutorCoversLevel } from '../catalog/compatibility.js';
import type { PublishedCategory } from '../catalog/catalog.service.js';
import type { CefrLevel, PublicTutor } from '../catalog/tutors.catalog.js';
import type { LearningGoal, LearningPreferences } from './user.schemas.js';

export interface Recommendation {
  tutorId: string;
  scenarioId: string | null;
  categoryIds: string[];
}

export interface RecommendOptions {
  categories: readonly PublishedCategory[];
  tutors: readonly PublicTutor[];
  /** Rotation seed, e.g. `${uid}:${localDate}`: stable within a day, varies across days. */
  seed?: string;
  /** Premium scenarios are only eligible with a server-verified premium entitlement. */
  includePremium?: boolean;
}

const GOAL_CATEGORIES: Record<LearningGoal, string[]> = {
  everyday: ['everyday'],
  career: ['professional'],
  business: ['professional'],
  travel_social: ['travel', 'social'],
  academic: ['academic'],
  confidence: ['everyday', 'social'],
};

/** FNV-1a: small, stable, dependency-free hash for deterministic rotation. */
function hash(seed: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

/** Content level for a learner. "Not sure" is treated as A2 and never shown as assessed. */
export function contentLevel(prefs: Partial<LearningPreferences> | null): CefrLevel {
  return !prefs?.level || prefs.level === 'not_sure' ? 'A2' : prefs.level;
}

/** Preferred tutor from goals and level; always one whose range covers the learner. */
function preferredTutor(goals: LearningGoal[], level: CefrLevel, tutors: readonly PublicTutor[]): PublicTutor {
  const byId = (id: string) => tutors.find((t) => t.id === id);
  const professional = goals.some((g) => g === 'career' || g === 'business' || g === 'academic');
  const order =
    professional && level !== 'A1'
      ? ['alex', 'emma', 'sofia']
      : cefrRank(level) <= cefrRank('A2')
        ? ['emma', 'sofia', 'alex']
        : goals.includes('travel_social') || goals.includes('everyday') || goals.includes('confidence')
          ? ['sofia', 'alex', 'emma']
          : ['emma', 'sofia', 'alex'];
  for (const id of order) {
    const t = byId(id);
    if (t && tutorCoversLevel(t, level)) return t;
  }
  return tutors.find((t) => tutorCoversLevel(t, level)) ?? tutors[0]!;
}

/**
 * Explainable starting recommendation (owner decision #6: every appropriate scenario
 * can be recommended).
 *
 * 1. Eligible scenarios: in the learner's goal categories, published, not premium
 *    (unless entitled), with the learner's level inside the scenario range. If none,
 *    the scenarios closest to the learner's level in those categories.
 * 2. Prefer eligible scenarios the preferred tutor is compatible with; otherwise use
 *    the scenario's suggested tutor (compatible by catalogue validation).
 * 3. Rotate among the pool with the seed, so every eligible scenario is reachable.
 */
export function recommend(prefs: Partial<LearningPreferences> | null, options: RecommendOptions): Recommendation {
  const goals = prefs?.goals?.length ? prefs.goals : (['everyday'] as LearningGoal[]);
  const level = contentLevel(prefs);
  const categoryIds = [...new Set(goals.flatMap((g) => GOAL_CATEGORIES[g]))];
  const tutor = preferredTutor(goals, level, options.tutors);

  const candidates = options.categories
    .filter((c) => categoryIds.includes(c.id))
    .flatMap((c) => c.scenarios.filter((s) => options.includePremium || !s.premium).map((s) => ({ c, s })));

  const distance = ({ s }: (typeof candidates)[number]) =>
    cefrRank(level) < cefrRank(s.cefr.min)
      ? cefrRank(s.cefr.min) - cefrRank(level)
      : Math.max(0, cefrRank(level) - cefrRank(s.cefr.max));
  const best = Math.min(...candidates.map(distance));
  const eligible = candidates.filter((x) => distance(x) === best);

  if (eligible.length === 0) return { tutorId: tutor.id, scenarioId: null, categoryIds };

  const withPreferred = eligible.filter(({ c, s }) => isTutorCompatible(tutor, c.id, s));
  const pool = withPreferred.length ? withPreferred : eligible;
  const pick = pool[hash(options.seed ?? '') % pool.length]!;
  return {
    tutorId: withPreferred.length ? tutor.id : pick.s.suggestedTutorId,
    scenarioId: pick.s.id,
    categoryIds,
  };
}
