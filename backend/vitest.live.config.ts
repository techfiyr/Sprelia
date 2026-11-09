import { defineConfig } from 'vitest/config';

/**
 * Opt-in live tests against real provider APIs (`npm run test:live`). They load secrets only via
 * Node's `--env-file-if-exists=../.env` and skip themselves when a key is not configured.
 * Never part of `npm test` or CI by default.
 */
export default defineConfig({
  test: {
    include: ['test/live/**/*.live.ts'],
    environment: 'node',
    testTimeout: 90_000,
    fileParallelism: false,
  },
});
