import { defineConfig } from 'vitest/config';

/** Runs only inside `firebase emulators:exec` (see `npm run test:integration`). */
export default defineConfig({
  test: {
    include: ['test/integration/**/*.test.ts'],
    // Fail closed: abort before any test runs unless we are on the local emulators.
    setupFiles: ['test/integration/setup.ts'],
    environment: 'node',
    testTimeout: 30_000,
    hookTimeout: 60_000,
    fileParallelism: false,
  },
});
