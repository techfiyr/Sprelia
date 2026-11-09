import { GoogleGenAI, Modality } from '@google/genai';
import { config } from './config.js';
import type { TutorConfig } from './tutors.js';

// SECURITY BOUNDARY (protected file): the permanent API key never leaves the backend.
const ai = new GoogleGenAI({ apiKey: config.geminiApiKey, httpOptions: { apiVersion: 'v1alpha' } });

export interface LiveTokenGrant {
  token: string;
  expiresAt: Date;
}

/**
 * Mints a single-use ephemeral token for one Live session. The model, persona,
 * voice and transcription settings are locked into the token, so a modified
 * client cannot change them. expireTime bounds the whole session, which acts
 * as a provider-side hard stop at the allowed duration.
 */
export async function createLiveToken(params: {
  tutor: TutorConfig;
  systemPrompt: string;
  allowedSeconds: number;
}): Promise<LiveTokenGrant> {
  const now = Date.now();
  const expiresAt = new Date(now + (params.allowedSeconds + 30) * 1000);

  const token = await ai.authTokens.create({
    config: {
      uses: 1,
      expireTime: expiresAt.toISOString(),
      newSessionExpireTime: new Date(now + 60 * 1000).toISOString(),
      liveConnectConstraints: {
        model: config.liveModel,
        config: {
          responseModalities: [Modality.AUDIO],
          systemInstruction: params.systemPrompt,
          speechConfig: {
            voiceConfig: { prebuiltVoiceConfig: { voiceName: params.tutor.voiceName } },
          },
          inputAudioTranscription: {},
          outputAudioTranscription: {},
        },
      },
      lockAdditionalFields: [],
    },
  });

  if (!token.name) throw new Error('Gemini did not return an ephemeral token');
  return { token: token.name, expiresAt };
}
