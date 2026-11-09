import { Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { FeedbackSchema, TranscriptLine, type Feedback } from './analysis.js';
import { termKey, type FeedbackRepository, type MistakeEntry, type StoredFeedback, type VocabularyEntry } from './feedback.repository.js';

const SCHEMA_VERSION = 1;
const toDate = (v: unknown) => (v instanceof Timestamp ? v.toDate() : new Date(0));

function toMistake(id: string, d: DocumentData): MistakeEntry {
  return {
    id,
    original: String(d.original ?? ''),
    improved: String(d.improved ?? ''),
    explanation: String(d.explanation ?? ''),
    category: String(d.category ?? 'grammar'),
    conversationId: String(d.conversationId ?? ''),
    createdAt: toDate(d.createdAt),
    mastered: d.mastered === true,
  };
}

function toVocabulary(id: string, d: DocumentData): VocabularyEntry {
  return {
    id,
    term: String(d.term ?? ''),
    meaning: String(d.meaning ?? ''),
    example: String(d.example ?? ''),
    conversationId: String(d.conversationId ?? ''),
    createdAt: toDate(d.createdAt),
    learned: d.learned === true,
  };
}

export class FirestoreFeedbackRepository implements FeedbackRepository {
  constructor(private readonly db: Firestore) {}

  private user(uid: string) {
    return this.db.collection('users').doc(uid);
  }
  private convo(uid: string, id: string) {
    return this.user(uid).collection('conversations').doc(id);
  }
  private analysis(uid: string, id: string) {
    return this.convo(uid, id).collection('feedback').doc('analysis');
  }

  async saveTranscript(uid: string, conversationId: string, transcript: TranscriptLine[], now: Date) {
    await this.convo(uid, conversationId).collection('private').doc('transcript').set({
      lines: transcript,
      storedAt: Timestamp.fromDate(now),
      schemaVersion: SCHEMA_VERSION,
    });
  }

  async getTranscript(uid: string, conversationId: string) {
    const snap = await this.convo(uid, conversationId).collection('private').doc('transcript').get();
    if (!snap.exists) return null;
    const parsed = TranscriptLine.array().safeParse(snap.get('lines'));
    return parsed.success ? parsed.data : null;
  }

  async getFeedback(uid: string, conversationId: string): Promise<StoredFeedback | null> {
    const snap = await this.analysis(uid, conversationId).get();
    if (!snap.exists) return null;
    const status = snap.get('status');
    if (status === 'completed') {
      const parsed = FeedbackSchema.safeParse(snap.get('feedback'));
      return { status, feedback: parsed.success ? parsed.data : null };
    }
    return { status: status === 'insufficient_speech' ? status : 'processing', feedback: null };
  }

  async claimFeedback(uid: string, conversationId: string, now: Date) {
    try {
      await this.analysis(uid, conversationId).create({ status: 'processing', createdAt: Timestamp.fromDate(now), schemaVersion: SCHEMA_VERSION });
      return true;
    } catch (err) {
      if ((err as { code?: number }).code === 6) return false; // ALREADY_EXISTS
      throw err;
    }
  }

  async completeFeedback(uid: string, conversationId: string, result: StoredFeedback, now: Date) {
    const at = Timestamp.fromDate(now);
    const batch = this.db.batch();
    batch.set(this.analysis(uid, conversationId), {
      status: result.status,
      feedback: result.feedback as Feedback | null,
      completedAt: at,
      schemaVersion: SCHEMA_VERSION,
    });
    for (const c of result.feedback?.corrections ?? []) {
      batch.create(this.user(uid).collection('mistakes').doc(), {
        original: c.original,
        improved: c.improved,
        explanation: c.explanation,
        category: c.category,
        conversationId,
        createdAt: at,
        mastered: false,
        schemaVersion: SCHEMA_VERSION,
      });
    }
    for (const v of result.feedback?.vocabulary ?? []) {
      // Same term again: refresh meaning/example, keep "learned" as it was.
      batch.set(
        this.user(uid).collection('vocabulary').doc(termKey(v.term)),
        { term: v.term, meaning: v.meaning, example: v.example, conversationId, createdAt: at, schemaVersion: SCHEMA_VERSION },
        { merge: true },
      );
    }
    await batch.commit();
  }

  async releaseFeedback(uid: string, conversationId: string) {
    await this.analysis(uid, conversationId).delete();
  }

  async listMistakes(uid: string, limit: number) {
    const snap = await this.user(uid).collection('mistakes').orderBy('createdAt', 'desc').limit(limit).get();
    return snap.docs.map((d) => toMistake(d.id, d.data()));
  }

  async setMistakeMastered(uid: string, id: string, mastered: boolean) {
    const ref = this.user(uid).collection('mistakes').doc(id);
    if (!(await ref.get()).exists) return false;
    await ref.update({ mastered });
    return true;
  }

  async listVocabulary(uid: string, limit: number) {
    const snap = await this.user(uid).collection('vocabulary').orderBy('createdAt', 'desc').limit(limit).get();
    return snap.docs.map((d) => toVocabulary(d.id, d.data()));
  }

  async setVocabularyLearned(uid: string, id: string, learned: boolean) {
    const ref = this.user(uid).collection('vocabulary').doc(id);
    if (!(await ref.get()).exists) return false;
    await ref.update({ learned });
    return true;
  }

  async counts(uid: string) {
    const mistakes = this.user(uid).collection('mistakes');
    const vocabulary = this.user(uid).collection('vocabulary');
    const [open, mastered, total, learned] = await Promise.all([
      mistakes.where('mastered', '==', false).count().get(),
      mistakes.where('mastered', '==', true).count().get(),
      vocabulary.count().get(),
      vocabulary.where('learned', '==', true).count().get(),
    ]);
    return {
      mistakesOpen: open.data().count,
      mistakesMastered: mastered.data().count,
      vocabulary: total.data().count,
      vocabularyLearned: learned.data().count,
    };
  }
}
