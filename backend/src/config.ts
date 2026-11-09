function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var ${name}`);
  return value;
}

export const config = {
  port: Number(process.env.PORT ?? 8080),
  geminiApiKey: required('GEMINI_API_KEY'),
  liveModel: process.env.GEMINI_LIVE_MODEL ?? 'gemini-2.5-flash-native-audio-preview-09-2025',
  analysisModel: process.env.GEMINI_ANALYSIS_MODEL ?? 'gemini-2.5-flash',
  freeDailySeconds: Number(process.env.FREE_DAILY_SECONDS ?? 600),
  devSkipAuth: process.env.DEV_SKIP_AUTH === 'true',
  liveWebsocketUrl:
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained',
};
