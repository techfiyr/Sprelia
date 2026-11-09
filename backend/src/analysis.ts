import { GoogleGenAI } from '@google/genai';
import { z } from 'zod';
import { config } from './config.js';

const ai = new GoogleGenAI({ apiKey: config.geminiApiKey });

export const FeedbackSchema = z.object({
  summary: z.string(),
  strengths: z.array(z.string()),
  corrections: z.array(
    z.object({
      original: z.string(),
      improved: z.string(),
      explanation: z.string(),
      category: z.enum(['grammar', 'vocabulary', 'sentence_construction', 'communication']),
      confidence: z.number().min(0).max(1),
    }),
  ),
  vocabulary: z.array(z.object({ term: z.string(), meaning: z.string(), example: z.string() })),
  fluency_observations: z.array(z.string()),
  recommended_practice: z.array(z.string()),
});
export type Feedback = z.infer<typeof FeedbackSchema>;

export interface TranscriptLine {
  speaker: 'user' | 'tutor';
  text: string;
}

const ANALYSIS_PROMPT = `
You are Hermione's English learning analyst. You receive the transcript of a spoken
practice conversation between a learner ("user") and an AI tutor ("tutor").

Produce feedback for the LEARNER only:
- summary: 1–2 friendly sentences on what was discussed and how it went.
- strengths: 1–3 specific things the learner did well, quoting their words where useful.
- corrections: only real errors in the learner's sentences. "original" must be the learner's
  words as transcribed; "improved" is the most natural fix; "explanation" is one short, plain sentence.
  Max 6, most useful first. Set confidence lower when the error might be a speech-recognition artifact.
- vocabulary: up to 5 useful words or phrases that fit the topic and learner level.
- fluency_observations: 1–3 communication tips based ONLY on the transcript (e.g. very short
  answers, repetition). Do NOT comment on pronunciation or accent — you only have text.
- recommended_practice: 1–2 concrete next practice suggestions.

Rules: Never invent mistakes. Accept all valid English varieties. Ignore filler words and
missing punctuation (they come from speech transcription). Pitch explanations at the learner's level.
`.trim();

export async function analyzeConversation(params: {
  transcript: TranscriptLine[];
  learnerLevel: string;
}): Promise<Feedback> {
  const transcriptText = params.transcript.map((l) => `${l.speaker}: ${l.text}`).join('\n');
  const response = await ai.models.generateContent({
    model: config.analysisModel,
    contents: `Learner CEFR level (self-reported): ${params.learnerLevel}\n\nTranscript:\n${transcriptText}`,
    config: {
      systemInstruction: ANALYSIS_PROMPT,
      responseMimeType: 'application/json',
      responseJsonSchema: z.toJSONSchema(FeedbackSchema),
      temperature: 0.2,
    },
  });
  const parsed = FeedbackSchema.parse(JSON.parse(response.text ?? '{}'));
  // Drop low-confidence corrections; LLM confidence is a rough model estimate, not calibrated.
  parsed.corrections = parsed.corrections.filter((c) => c.confidence >= 0.6);
  return parsed;
}
