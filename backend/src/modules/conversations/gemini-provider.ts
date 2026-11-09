import { GoogleGenAI, Modality } from '@google/genai';
import { UnavailableAIProvider, type AIProvider, type RealtimeGrant, type RealtimeSessionRequest } from './ai-provider.js';

/**
 * Gemini Live via ephemeral tokens (verified against the official docs, 2026-11-09):
 * - tokens are created with the `v1beta` API and used on
 *   `…v1beta.GenerativeService.BidiGenerateContentConstrained?access_token=<token>`;
 * - `uses: 1`, `newSessionExpireTime` (start window) and `expireTime` (whole session);
 * - `liveConnectConstraints` locks model, persona, voice and transcription, and
 *   `lockAdditionalFields: []` locks every field that is set (SDK "Case 4"), so a modified
 *   client cannot change them;
 * - audio: PCM16 16 kHz in, 24 kHz out (handled by the app).
 */
export const GEMINI_LIVE_WS_URL =
  'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained';

/** Grace period after the reserved time before the token stops working. */
const TOKEN_SLACK_SECONDS = 30;
const START_WINDOW_SECONDS = 60;

export class GeminiProvider implements AIProvider {
  readonly available = true;
  private readonly ai: GoogleGenAI;

  constructor(
    apiKey: string,
    private readonly liveModel: string,
    private readonly now: () => Date = () => new Date(),
  ) {
    this.ai = new GoogleGenAI({ apiKey, httpOptions: { apiVersion: 'v1beta' } });
  }

  async createRealtimeSession(request: RealtimeSessionRequest): Promise<RealtimeGrant> {
    const now = this.now().getTime();
    const expiresAt = new Date(now + (request.allowedSeconds + TOKEN_SLACK_SECONDS) * 1000);
    const token = await this.ai.authTokens.create({
      config: {
        uses: 1,
        expireTime: expiresAt.toISOString(),
        newSessionExpireTime: new Date(now + START_WINDOW_SECONDS * 1000).toISOString(),
        liveConnectConstraints: {
          model: this.liveModel,
          config: {
            responseModalities: [Modality.AUDIO],
            systemInstruction: request.systemPrompt,
            speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: request.voiceName } } },
            inputAudioTranscription: {},
            outputAudioTranscription: {},
          },
        },
        lockAdditionalFields: [],
      },
    });
    if (!token.name) throw new Error('Gemini did not return an ephemeral token');
    return { provider: 'gemini', token: token.name, model: this.liveModel, websocketUrl: GEMINI_LIVE_WS_URL, expiresAt };
  }
}

/**
 * Explicit provider choice: Gemini when GEMINI_API_KEY is configured, otherwise a provider that
 * reports itself unavailable (voice endpoints answer 503 VOICE_UNAVAILABLE; nothing crashes).
 */
export function createAIProvider(config: { geminiApiKey?: string; geminiLiveModel: string }): AIProvider {
  return config.geminiApiKey ? new GeminiProvider(config.geminiApiKey, config.geminiLiveModel) : new UnavailableAIProvider();
}
