import { PRACTICE_CATEGORIES } from '../catalog/practice.catalog.js';
import type { CefrLevel } from '../catalog/tutors.catalog.js';
import type { LearningGoal, LearningPreferences } from './user.schemas.js';

export interface Recommendation {
  tutorId: string;
  scenarioId: string | null;
  categoryIds: string[];
}

const GOAL_CATEGORIES: Record<LearningGoal, string[]> = {
  everyday: ['everyday'],
  career: ['professional'],
  business: ['professional'],
  travel_social: ['travel', 'social'],
  academic: ['academic'],
  confidence: ['everyday', 'social'],
};

const ORDER: CefrLevel[] = ['A1', 'A2', 'B1', 'B2', 'C1'];
const rank = (l: CefrLevel) => ORDER.indexOf(l);

/**
 * Deterministic, explainable starting recommendation from onboarding answers.
 * "Not sure" is treated as A2 for content difficulty only; it is never shown
 * to the learner as an assessed level.
 */
export function recommend(prefs: Partial<LearningPreferences> | null): Recommendation {
  const goals = prefs?.goals?.length ? prefs.goals : (['everyday'] as LearningGoal[]);
  const level: CefrLevel = !prefs?.level || prefs.level === 'not_sure' ? 'A2' : prefs.level;

  const categoryIds = [...new Set(goals.flatMap((g) => GOAL_CATEGORIES[g]))];

  const professionalFocus = goals.some((g) => g === 'career' || g === 'business' || g === 'academic');
  const beginner = rank(level) <= rank('A2');
  const tutorId = professionalFocus && level !== 'A1' ? 'alex' : beginner ? 'emma' : goals.includes('travel_social') ? 'sofia' : 'emma';

  let scenarioId: string | null = null;
  for (const categoryId of categoryIds) {
    const category = PRACTICE_CATEGORIES.find((c) => c.id === categoryId);
    const match = category?.scenarios.find(
      (s) => !s.premium && rank(s.cefr.min) <= rank(level) && rank(level) <= rank(s.cefr.max),
    );
    if (match) {
      scenarioId = match.id;
      break;
    }
  }

  return { tutorId, scenarioId, categoryIds };
}
