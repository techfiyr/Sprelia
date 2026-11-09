/**
 * Vendor-neutral AI boundary (APP_DEVELOPMENT §9). The app talks to the realtime vendor
 * directly with a short-lived grant minted here; the permanent API key never leaves the backend.
 */
export interface RealtimeSessionRequest {
  /** Persona, rules, scenario and learner context; locked into the grant. */
  systemPrompt: string;
  voiceName: string;
  /** Hard cap for the whole session (the grant expires shortly after). */
  allowedSeconds: number;
}

export interface RealtimeGrant {
  provider: 'gemini';
  token: string;
  model: string;
  websocketUrl: string;
  expiresAt: Date;
}

export interface AIProvider {
  /** False when the provider is not configured (no API key). */
  readonly available: boolean;
  createRealtimeSession(request: RealtimeSessionRequest): Promise<RealtimeGrant>;
}

export class UnavailableAIProvider implements AIProvider {
  readonly available = false;
  async createRealtimeSession(): Promise<RealtimeGrant> {
    throw new Error('AI provider not configured');
  }
}

/** Why voice is (un)available, for startup logs and health/ops. Never includes the key. */
export function aiProviderStatus(config: { geminiApiKey?: string }): 'gemini' | 'unavailable: GEMINI_API_KEY not set' {
  return config.geminiApiKey ? 'gemini' : 'unavailable: GEMINI_API_KEY not set';
}
