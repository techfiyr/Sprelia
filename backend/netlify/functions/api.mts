/**
 * Netlify Function entry point for the Sprelia API (owner hosting decision 2026-11-09).
 *
 * - Serves every route under /api/* (the Fastify app's own prefix is /api/v1), so URLs are the
 *   same as on any other host. With a custom `path`, the default /.netlify/functions/api URL
 *   is not exposed (Netlify docs: build/functions/configuration).
 * - Runs on the Netlify free plan in Netlify's default function region (owner decision
 *   2026-11-09; no region is set). Firestore stays in asia-southeast1 (Singapore), so every
 *   API request crosses regions (added latency on Firestore and Auth calls).
 * - Synchronous functions have a 60-second limit and a 6 MB buffered payload limit.
 * - Configuration comes from Netlify environment variables (see doc/DEPLOYMENT_NETLIFY.md).
 *   Firebase credential: the FIREBASE_SERVICE_ACCOUNT_JSON Netlify environment secret (owner
 *   authorized 2026-11-09). Nothing secret is in this file.
 */
import { createLogger } from '../../src/common/logger.js';
import { loadConfig } from '../../src/config/env.js';
import { createRuntimeApp } from '../../src/runtime.js';
import { assertNetlifyConfig, createNetlifyHandler } from '../../src/serverless/netlify.js';

export default createNetlifyHandler(async () => {
  const appConfig = loadConfig();
  assertNetlifyConfig(appConfig);
  return createRuntimeApp(appConfig, createLogger(appConfig));
});

export const config = {
  path: '/api/*',
};
