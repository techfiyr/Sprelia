import type { FastifyPluginAsync } from 'fastify';
import { AppError, ErrorCode, validationError } from '../../common/errors.js';
import { validate } from '../../common/validate.js';
import { authenticate, requireUser, requireVerifiedEmail } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import type { CatalogService } from '../catalog/catalog.service.js';
import { buildDashboard } from './dashboard.js';
import { localDate } from './local-date.js';
import { recommend } from './recommendation.js';
import {
  OnboardingIncompleteError,
  ProfileNotFoundError,
  TimezoneChangeTooSoonError,
  type UserProfile,
  type UserRepository,
} from './user.repository.js';
import {
  CreateProfileBody,
  SaveOnboardingBody,
  UpdatePreferencesBody,
  UpdateProfileBody,
  type LearningPreferences,
} from './user.schemas.js';

export interface ProfileRoutesOptions {
  verifier: TokenVerifier;
  users: UserRepository;
  freeDailySeconds: number;
  now: () => Date;
  catalog: CatalogService;
  /** Email/password accounts must verify their email first (config REQUIRE_EMAIL_VERIFICATION). */
  requireEmailVerification?: boolean;
}

const profileNotFound = () =>
  new AppError(404, ErrorCode.PROFILE_NOT_FOUND, 'Your profile has not been created yet.');

function serializeProfile(p: UserProfile, preferences: Partial<LearningPreferences> | null) {
  return {
    uid: p.uid,
    email: p.email,
    displayName: p.displayName,
    timezone: p.timezone,
    preferredTutorId: p.preferredTutorId,
    practiceReminders: p.practiceReminders,
    onboarding: {
      status: p.onboardingStatus,
      completedAt: p.onboardingCompletedAt?.toISOString() ?? null,
      preferences: preferences ?? {},
    },
    createdAt: p.createdAt.toISOString(),
    updatedAt: p.updatedAt.toISOString(),
  };
}

/**
 * User-owned resources under /me. Ownership is structural: every operation uses
 * the uid from the verified token, and no route accepts a uid parameter.
 */
export const profileRoutes: FastifyPluginAsync<ProfileRoutesOptions> = async (app, opts) => {
  const { users } = opts;
  app.addHook('preHandler', authenticate(opts.verifier));
  app.addHook('preHandler', requireVerifiedEmail(opts.requireEmailVerification ?? true));
  app.addHook('onSend', async (_request, reply) => {
    reply.header('cache-control', 'private, no-store');
  });

  app.get('/me/profile', async (request) => {
    const { uid } = requireUser(request);
    const profile = await users.getProfile(uid);
    if (!profile) throw profileNotFound();
    return { profile: serializeProfile(profile, await users.getPreferences(uid)) };
  });

  app.post<{ Body: CreateProfileBody }>(
    '/me/profile',
    { preHandler: validate({ body: CreateProfileBody }) },
    async (request, reply) => {
      const user = requireUser(request);
      const { profile, created } = await users.createProfileIfAbsent({
        uid: user.uid,
        email: user.email ?? null,
        displayName: request.body.displayName ?? null,
        timezone: request.body.timezone,
      });
      reply.status(created ? 201 : 200);
      return { profile: serializeProfile(profile, await users.getPreferences(user.uid)), created };
    },
  );

  app.put<{ Body: SaveOnboardingBody }>(
    '/me/onboarding',
    { preHandler: validate({ body: SaveOnboardingBody }) },
    async (request) => {
      const { uid } = requireUser(request);
      try {
        const { profile, preferences } = await users.saveOnboarding(uid, request.body.preferences, request.body.complete);
        return {
          profile: serializeProfile(profile, preferences),
          plan:
            profile.onboardingStatus === 'completed'
              ? recommend(preferences, {
                  categories: opts.catalog.publishedCategories(),
                  tutors: opts.catalog.tutors,
                  seed: `${uid}:${localDate(profile.timezone, opts.now())}`,
                  chosenTutorId: profile.preferredTutorId,
                })
              : null,
        };
      } catch (err) {
        if (err instanceof ProfileNotFoundError) throw profileNotFound();
        if (err instanceof OnboardingIncompleteError) {
          throw validationError(
            err.missing.map((field) => ({ path: `body.preferences.${field}`, message: 'required to complete onboarding' })),
          );
        }
        throw err;
      }
    },
  );

  /** Time zone changes move the daily quota boundary, so they are limited to one per day. */
  const TIMEZONE_CHANGE_INTERVAL_MS = 24 * 60 * 60 * 1000;

  app.patch<{ Body: UpdateProfileBody }>(
    '/me/profile',
    { preHandler: validate({ body: UpdateProfileBody }) },
    async (request) => {
      const { uid } = requireUser(request);
      const { preferredTutorId } = request.body;
      if (preferredTutorId && !opts.catalog.tutors.some((t) => t.id === preferredTutorId)) {
        throw validationError([{ path: 'body.preferredTutorId', message: 'unknown tutor' }]);
      }
      try {
        const profile = await users.updateProfile(uid, request.body, {
          now: opts.now(),
          minTimezoneIntervalMs: TIMEZONE_CHANGE_INTERVAL_MS,
        });
        return { profile: serializeProfile(profile, await users.getPreferences(uid)) };
      } catch (err) {
        if (err instanceof ProfileNotFoundError) throw profileNotFound();
        if (err instanceof TimezoneChangeTooSoonError) {
          throw new AppError(429, ErrorCode.TIMEZONE_CHANGE_TOO_SOON, 'You can change your time zone once a day. Please try again later.', [
            { path: 'body.timezone', message: `retry after ${err.retryAfter.toISOString()}` },
          ]);
        }
        throw err;
      }
    },
  );

  app.patch<{ Body: UpdatePreferencesBody }>(
    '/me/preferences',
    { preHandler: validate({ body: UpdatePreferencesBody }) },
    async (request) => {
      const { uid } = requireUser(request);
      try {
        // Same validated merge as onboarding; a completed onboarding stays completed.
        const { profile, preferences } = await users.saveOnboarding(uid, request.body.preferences, false);
        return { profile: serializeProfile(profile, preferences) };
      } catch (err) {
        if (err instanceof ProfileNotFoundError) throw profileNotFound();
        throw err;
      }
    },
  );

  /** The caller's own data as JSON (APP_FLOW §17 "data export, where supported"). */
  app.get('/me/export', async (request, reply) => {
    const { uid } = requireUser(request);
    const data = await users.exportUserData(uid);
    if (!data) throw profileNotFound();
    reply.header('content-disposition', 'attachment; filename="sprelia-data-export.json"');
    return {
      exportedAt: opts.now().toISOString(),
      format: 'sprelia-export-v1',
      profile: serializeProfile(data.profile, data.preferences),
      usage: data.usage,
      dailyProgress: data.dailyProgress,
      conversations: data.conversations,
      mistakes: data.mistakes,
      vocabulary: data.vocabulary,
    };
  });

  app.get('/me/dashboard', async (request) => {
    const { uid } = requireUser(request);
    const profile = await users.getProfile(uid);
    if (!profile) throw profileNotFound();
    return {
      dashboard: await buildDashboard(users, profile, {
        now: opts.now(),
        freeDailySeconds: opts.freeDailySeconds,
        catalog: opts.catalog,
      }),
    };
  });
};
