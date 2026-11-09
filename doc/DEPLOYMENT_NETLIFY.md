# Netlify deployment (API + website)

**Owner hosting decision (2026-11-09):** the Sprelia API and website are hosted on **Netlify**.
This supersedes Cloud Run in `APP_DEVELOPMENT.md` §3/§12/§17. **Plan: Netlify free plan, default
function region** (owner decision 2026-11-09; no paid plan or region setting is required).

## What one deploy publishes
| Part | Source | URL |
|---|---|---|
| API (Netlify Function `api`) | `backend/netlify/functions/api.mts` → the existing Fastify app via `src/serverless/netlify.ts` | `/api/*` (routes under `/api/v1`, unchanged) |
| Website: landing page, Privacy, Terms, AI disclaimer, Content policy, Cookies, 404 | `backend/netlify/public/` | `/`, `/privacy/`, `/terms/`, `/ai-disclaimer/`, `/content-policy/`, `/cookies/` |

`netlify.toml` (repo root): base `backend`, build command `npm run typecheck`, publish
`netlify/public` (**only** that folder, never the backend source), functions from
`netlify/functions` bundled with esbuild (`firebase-admin`, `@google-cloud/firestore`, `google-gax`
shipped as node modules), and first-party-only security headers for the site.

## Platform facts (Netlify docs, verified 2026-11-09)
- Function region: **none set**, so Netlify's default region is used (documented as US East,
  Ohio). Firestore is in **`us-east5` (Columbus, Ohio)**, so the function and the database are in
  the same US East area; no cross-region penalty is expected. Choosing a function region requires a
  paid plan and is not used.
- Synchronous functions: **60-second** execution limit; **6 MB** buffered request/response payload.
- A custom `path` means the function is only reachable at that path (not `/.netlify/functions/api`).
- Client IP: `context.ip`. The adapter uses only this and ignores caller-supplied forwarding
  headers, so `TRUST_PROXY_HOPS` must be `0` (enforced at startup).

## Serverless caveats
- **Rate limiting is per function instance, not global.** `@fastify/rate-limit` keeps counters in
  memory; it slows a noisy client on a warm instance but is **not** distributed protection. A
  shared store (or Netlify/edge-level limits) is needed before relying on it.
- Cold starts include Firebase Admin initialization. The app is reused while an instance is warm.
- Long-lived or streaming endpoints are not suitable. Planned live voice connects the app directly
  to Gemini with short-lived tokens, so it fits this model.

## Credentials
Netlify has no Google Cloud workload identity, so the API authenticates to Firebase with a
service-account key stored as the **`FIREBASE_SERVICE_ACCOUNT_JSON`** Netlify environment secret.
**Authorized by the owner on 2026-11-09** (an explicit exception to the repo's "no key files" rule,
for this Netlify secret only). Status: **not set yet**; the owner enters it in the Netlify UI.

- The key is never committed, never placed in `netlify.toml` or app files, never logged, and never
  printed or uploaded by the agent.
- Recommended follow-up (owner): move to a dedicated least-privilege service account and rotate
  the current key (`sprelia-c6a0682eb252`).

When `FIREBASE_SERVICE_ACCOUNT_JSON` is set, the backend:
- parses it strictly at startup (JSON object, `type: service_account`, `project_id` and
  `client_email` must match `FIREBASE_PROJECT_ID`, PEM private key present);
- never logs it (redacted paths; the private key is non-enumerable) and never echoes it in errors;
- refuses it with the emulators, `demo-*` projects or `APP_ENV=test`;
- falls back to Application Default Credentials when it is unset (local `gcloud` login).

The key is never committed, never placed in `netlify.toml`, and never uploaded by the agent.

## Owner steps (not done by the agent)
1. **Plan:** the Netlify free plan is enough (default function region).
2. **Credential (authorized):** have the service-account JSON ready locally. Plan to rotate it to a
   dedicated least-privilege key later; keep every key JSON outside the repo.
3. **Connect the repository (Netlify UI, no CLI deploy):** *Add new project* → *Import an existing
   project* → GitHub → `techfiyr/Sprelia`, branch `main`. Netlify reads `netlify.toml`, so leave
   base/publish/functions fields as detected. Before the first build completes, add the
   environment variables below (the import screen offers *Add environment variables*); if a build
   starts first, let it fail or stop it, then redeploy once the variables are set, so the API is
   never published without its credential.
4. **Environment variables** (*Project configuration → Environment variables*), scoped to
   **Functions** unless noted:
   | Key | Value |
   |---|---|
   | `APP_ENV` | `staging` (pre-launch; `production` requires `APP_CHECK_MODE=enforce`) |
   | `FIREBASE_PROJECT_ID` | `sprelia` |
   | `TRUST_PROXY_HOPS` | `0` |
   | `APP_CHECK_MODE` | `off` (App Check deferred) |
   | `REQUIRE_EMAIL_VERIFICATION` | `true` |
   | `LOG_LEVEL` | `info` |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | the entire key file content, marked **Contains secret values**, scope **Functions**. Set it **before** the first deploy finishes |
   | `NODE_VERSION` (Builds scope) | a Netlify-supported Node.js version ≥ 22 |

   Check Netlify's current limit on the total size of function environment variables: the key is
   about 2–3 KB, so keep the other variables short.
5. **Deploy (owner approved 2026-11-09) after the variables are set.** Then check `https://<site>/api/v1/health` (expect `{"status":"ok"}`),
   the site pages, and that `/api/v1/me` without a token returns 401.
6. **App:** set `API_BASE_URL=https://<site>.netlify.app` (or the custom domain) in the gitignored
   `env/staging.json` / `env/production.json`.
7. **Before public launch:** review the legal drafts (`doc/reviews/LEGAL_PAGES_REVIEW.md`), remove
   `Disallow: /` from `robots.txt` and the `noindex` tags once the pages are approved.

## Local checks
`cd backend && npm run typecheck && npm test && npm run build` (adapter, config, site and consent
tests use fakes; no Netlify or Firebase access).
