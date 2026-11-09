import type { TranscriptLine } from './analysis.js';
import { termKey, type FeedbackRepository, type MistakeEntry, type StoredFeedback, type VocabularyEntry } from './feedback.repository.js';

/** In-memory twin for unit tests. */
export class InMemoryFeedbackRepository implements FeedbackRepository {
  readonly transcripts = new Map<string, TranscriptLine[]>();
  readonly feedback = new Map<string, StoredFeedback>();
  readonly mistakes = new Map<string, MistakeEntry>(); // `${uid}/${id}`
  readonly vocabulary = new Map<string, VocabularyEntry>(); // `${uid}/${termKey}`
  private seq = 0;

  async saveTranscript(uid: string, id: string, transcript: TranscriptLine[]) {
    this.transcripts.set(`${uid}/${id}`, transcript);
  }
  async getTranscript(uid: string, id: string) {
    return this.transcripts.get(`${uid}/${id}`) ?? null;
  }
  async getFeedback(uid: string, id: string) {
    return this.feedback.get(`${uid}/${id}`) ?? null;
  }
  async claimFeedback(uid: string, id: string) {
    if (this.feedback.has(`${uid}/${id}`)) return false;
    this.feedback.set(`${uid}/${id}`, { status: 'processing', feedback: null });
    return true;
  }
  async completeFeedback(uid: string, id: string, result: StoredFeedback, now: Date) {
    this.feedback.set(`${uid}/${id}`, result);
    for (const c of result.feedback?.corrections ?? []) {
      const mid = `m${++this.seq}`;
      this.mistakes.set(`${uid}/${mid}`, { id: mid, ...c, conversationId: id, createdAt: new Date(now.getTime() + this.seq), mastered: false });
    }
    for (const v of result.feedback?.vocabulary ?? []) {
      const key = `${uid}/${termKey(v.term)}`;
      const prev = this.vocabulary.get(key);
      this.vocabulary.set(key, { id: termKey(v.term), ...v, conversationId: id, createdAt: now, learned: prev?.learned ?? false });
    }
  }
  async releaseFeedback(uid: string, id: string) {
    this.feedback.delete(`${uid}/${id}`);
  }
  private own<T>(map: Map<string, T>, uid: string) {
    return [...map.entries()].filter(([k]) => k.startsWith(`${uid}/`)).map(([, v]) => v);
  }
  async listMistakes(uid: string, limit: number) {
    return this.own(this.mistakes, uid).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()).slice(0, limit);
  }
  async setMistakeMastered(uid: string, id: string, mastered: boolean) {
    const m = this.mistakes.get(`${uid}/${id}`);
    if (!m) return false;
    this.mistakes.set(`${uid}/${id}`, { ...m, mastered });
    return true;
  }
  async listVocabulary(uid: string, limit: number) {
    return this.own(this.vocabulary, uid).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()).slice(0, limit);
  }
  async setVocabularyLearned(uid: string, id: string, learned: boolean) {
    const v = this.vocabulary.get(`${uid}/${id}`);
    if (!v) return false;
    this.vocabulary.set(`${uid}/${id}`, { ...v, learned });
    return true;
  }
  async counts(uid: string) {
    const m = this.own(this.mistakes, uid);
    const v = this.own(this.vocabulary, uid);
    return {
      mistakesOpen: m.filter((x) => !x.mastered).length,
      mistakesMastered: m.filter((x) => x.mastered).length,
      vocabulary: v.length,
      vocabularyLearned: v.filter((x) => x.learned).length,
    };
  }
}
