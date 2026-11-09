/**
 * Fail-closed guard for the integration suite (run by `setup.ts` before any test file, and
 * again right before every destructive emulator request). Pure, so it is unit-tested too.
 *
 * The suite wipes Auth accounts and Firestore documents. It must only ever do that on the
 * local Firebase Emulator Suite with a `demo-*` project, never on `sprelia` or any real
 * project, whatever the environment says.
 */
export const EMULATOR_PROJECT_ID = 'demo-sprelia';

const LOCAL_HOST = /^(127\.0\.0\.1|localhost|\[::1\]):\d{2,5}$/;

export function assertEmulatorOnly(env: NodeJS.ProcessEnv = process.env): { authHost: string; firestoreHost: string } {
  const authHost = env.FIREBASE_AUTH_EMULATOR_HOST ?? '';
  const firestoreHost = env.FIRESTORE_EMULATOR_HOST ?? '';
  const problems: string[] = [];
  if (!LOCAL_HOST.test(authHost)) problems.push('FIREBASE_AUTH_EMULATOR_HOST must point to a local emulator');
  if (!LOCAL_HOST.test(firestoreHost)) problems.push('FIRESTORE_EMULATOR_HOST must point to a local emulator');
  for (const key of ['GCLOUD_PROJECT', 'GOOGLE_CLOUD_PROJECT', 'FIREBASE_PROJECT_ID'] as const) {
    const value = env[key];
    if (value && !value.startsWith('demo-')) problems.push(`${key} must be a demo-* project`);
  }
  if (env.GOOGLE_APPLICATION_CREDENTIALS) problems.push('GOOGLE_APPLICATION_CREDENTIALS must not be set for emulator tests');
  if (problems.length) {
    throw new Error(`Refusing to run integration tests outside the emulators:\n  - ${problems.join('\n  - ')}\nRun \`npm run test:integration\`.`);
  }
  return { authHost, firestoreHost };
}
