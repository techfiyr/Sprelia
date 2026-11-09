import type { Feedback, TranscriptLine } from './analysis.js';

/**
 * Learning data (Phase 8), under users/{uid}:
 *   conversations/{id}/private/transcript   uploaded transcript (retention: pending owner decision)
 *   conversations/{id}/feedback/analysis    {status, feedback?}
 *   mistakes/{auto}                          Mistake Vault entries (from validated corrections)
 *   vocabulary/{termKey}                     saved words (deduplicated by term)
 */
export type FeedbackStatus = 'processing' | 'completed' | 'insufficient_speech';

export interface StoredFeedback {
  status: FeedbackStatus;
  feedback: Feedback | null;
}

export interface MistakeEntry {
  id: string;
  original: string;
  improved: string;
  explanation: string;
  category: string;
  conversationId: string;
  createdAt: Date;
  mastered: boolean;
}

export interface VocabularyEntry {
  id: string;
  term: string;
  meaning: string;
  example: string;
  conversationId: string;
  createdAt: Date;
  learned: boolean;
}

export interface FeedbackRepository {
  saveTranscript(uid: string, conversationId: string, transcript: TranscriptLine[], now: Date): Promise<void>;
  getTranscript(uid: string, conversationId: string): Promise<TranscriptLine[] | null>;
  getFeedback(uid: string, conversationId: string): Promise<StoredFeedback | null>;
  /** Creates the "processing" marker; false if feedback already exists or is being generated. */
  claimFeedback(uid: string, conversationId: string, now: Date): Promise<boolean>;
  /** Stores the result and adds mistakes and vocabulary atomically. */
  completeFeedback(uid: string, conversationId: string, result: StoredFeedback, now: Date): Promise<void>;
  /** Removes the marker after a failure so generation can be retried. */
  releaseFeedback(uid: string, conversationId: string): Promise<void>;
  listMistakes(uid: string, limit: number): Promise<MistakeEntry[]>;
  setMistakeMastered(uid: string, id: string, mastered: boolean): Promise<boolean>;
  listVocabulary(uid: string, limit: number): Promise<VocabularyEntry[]>;
  setVocabularyLearned(uid: string, id: string, learned: boolean): Promise<boolean>;
  counts(uid: string): Promise<{ mistakesOpen: number; mistakesMastered: number; vocabulary: number; vocabularyLearned: number }>;
}

/** Stable document ID for a vocabulary term (deduplication). */
export function termKey(term: string): string {
  const k = term.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60);
  return k || 'term';
}
