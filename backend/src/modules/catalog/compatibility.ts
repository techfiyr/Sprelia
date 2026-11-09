import { SCENARIO_DURATIONS, type PracticeCategory, type Scenario } from './practice.catalog.js';
import type { CefrLevel, PublicTutor } from './tutors.catalog.js';

export const CEFR_ORDER: readonly CefrLevel[] = ['A1', 'A2', 'B1', 'B2', 'C1'];
export const cefrRank = (level: CefrLevel) => CEFR_ORDER.indexOf(level);

/** The tutor's level range covers the learner's level. */
export function tutorCoversLevel(tutor: PublicTutor, level: CefrLevel): boolean {
  return cefrRank(tutor.levels.min) <= cefrRank(level) && cefrRank(level) <= cefrRank(tutor.levels.max);
}

/**
 * Tutor–scenario compatibility (owner decision #8, enforced on the backend):
 * the tutor explicitly supports the scenario's category AND the tutor's level range
 * fully contains the scenario's level range.
 */
export function isTutorCompatible(tutor: PublicTutor, categoryId: string, scenario: Scenario): boolean {
  return (
    tutor.categoryIds.includes(categoryId) &&
    cefrRank(tutor.levels.min) <= cefrRank(scenario.cefr.min) &&
    cefrRank(scenario.cefr.max) <= cefrRank(tutor.levels.max)
  );
}

export function compatibleTutorIds(tutors: readonly PublicTutor[], categoryId: string, scenario: Scenario): string[] {
  return tutors.filter((t) => isTutorCompatible(t, categoryId, scenario)).map((t) => t.id);
}

/**
 * Validates the whole catalogue. Returns human-readable problems (empty = valid).
 * The API refuses to start with an invalid catalogue (see catalog.service.ts).
 */
export function validateCatalog(categories: readonly PracticeCategory[], tutors: readonly PublicTutor[]): string[] {
  const problems: string[] = [];
  const ids = new Set<string>();
  for (const category of categories) {
    for (const s of category.scenarios) {
      const where = `${category.id}/${s.id}`;
      if (ids.has(s.id)) problems.push(`${where}: duplicate scenario id`);
      ids.add(s.id);
      if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(s.id)) problems.push(`${where}: id must be kebab-case`);
      if (cefrRank(s.cefr.min) > cefrRank(s.cefr.max)) problems.push(`${where}: CEFR min above max`);
      if (!(SCENARIO_DURATIONS as readonly number[]).includes(s.estimatedMinutes)) {
        problems.push(`${where}: duration ${s.estimatedMinutes} not in ${SCENARIO_DURATIONS.join('/')}`);
      }
      if (s.objectives.length < 2) problems.push(`${where}: needs at least 2 objectives`);
      if (s.vocabulary.length < 3) problems.push(`${where}: needs at least 3 vocabulary items`);
      if (s.reviewStatus === 'approved' && (!s.reviewedBy || !s.reviewedAt)) {
        problems.push(`${where}: approved scenarios need reviewedBy and reviewedAt`);
      }
      const tutor = tutors.find((t) => t.id === s.suggestedTutorId);
      if (!tutor) {
        problems.push(`${where}: unknown suggested tutor ${s.suggestedTutorId}`);
      } else if (!isTutorCompatible(tutor, category.id, s)) {
        problems.push(
          `${where}: suggested tutor ${tutor.id} (${tutor.levels.min}–${tutor.levels.max}, ` +
            `${tutor.categoryIds.join('/')}) is not compatible with ${s.cefr.min}–${s.cefr.max} ${category.id}`,
        );
      }
    }
  }
  return problems;
}
