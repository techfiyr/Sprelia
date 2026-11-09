import { describe, expect, it } from 'vitest';
import { GEMINI_LIVE_WS_URL, GeminiProvider } from '../../src/modules/conversations/gemini-provider.js';
import { buildSystemPrompt, PERSONAS } from '../../src/modules/conversations/personas.js';

/**
 * Live Gemini check (costs nothing beyond a token and a session setup; no audio is sent):
 * 1. mint a constrained ephemeral token with the real key (v1beta),
 * 2. open the Live WebSocket with that token, send the setup message the app sends, and wait for
 *    `setupComplete`, proving the model ID, voice and constraints are accepted,
 * 3. close immediately. The key and token are never printed.
 */
const key = process.env.GEMINI_API_KEY;
const model = process.env.GEMINI_LIVE_MODEL ?? 'gemini-3.8-live';

describe.skipIf(!key)('Gemini Live (live API)', () => {
  it('mints a constrained ephemeral token and completes a Live session setup', async () => {
    const provider = new GeminiProvider(key!, model);
    const grant = await provider.createRealtimeSession({
      systemPrompt: buildSystemPrompt({ persona: PERSONAS.emma!, level: 'A2', accent: 'american', scenario: null }),
      voiceName: PERSONAS.emma!.voiceName,
      allowedSeconds: 60,
    });
    expect(grant.token).toMatch(/^auth_tokens\//);
    expect(grant.websocketUrl).toBe(GEMINI_LIVE_WS_URL);

    const outcome = await new Promise<string>((resolve) => {
      const ws = new WebSocket(`${grant.websocketUrl}?access_token=${encodeURIComponent(grant.token)}`);
      const timer = setTimeout(() => {
        ws.close();
        resolve('timeout');
      }, 20_000);
      ws.onopen = () =>
        ws.send(
          JSON.stringify({
            setup: {
              model: `models/${grant.model}`,
              generationConfig: { responseModalities: ['AUDIO'] },
              inputAudioTranscription: {},
              outputAudioTranscription: {},
            },
          }),
        );
      ws.onmessage = async (event) => {
        const text = typeof event.data === 'string' ? event.data : await (event.data as Blob).text();
        if (text.includes('setupComplete')) {
          clearTimeout(timer);
          ws.close();
          resolve('setupComplete');
        }
      };
      ws.onclose = (event) => {
        clearTimeout(timer);
        resolve(`closed ${event.code}: ${String(event.reason).slice(0, 120)}`);
      };
    });
    expect(outcome).toBe('setupComplete');
  });
});

describe.runIf(!key)('Gemini Live (not configured)', () => {
  it('is skipped because GEMINI_API_KEY is not set', () => {
    expect(key).toBeUndefined();
  });
});
