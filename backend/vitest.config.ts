import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/**/*.test.ts'],
    // Emulator-backed tests run via `npm run test:integration`.
    exclude: ['test/integration/**', 'node_modules/**'],
    environment: 'node',
  },
});
