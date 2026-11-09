/**
 * Application error model. Every error that reaches a client is one of these codes
 * with a safe, user-facing message. Internal details stay in the logs.
 */
export const ErrorCode = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  BAD_REQUEST: 'BAD_REQUEST',
  UNAUTHENTICATED: 'UNAUTHENTICATED',
  INVALID_TOKEN: 'INVALID_TOKEN',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  PROFILE_NOT_FOUND: 'PROFILE_NOT_FOUND',
  RATE_LIMITED: 'RATE_LIMITED',
  PAYLOAD_TOO_LARGE: 'PAYLOAD_TOO_LARGE',
  UNSUPPORTED_MEDIA_TYPE: 'UNSUPPORTED_MEDIA_TYPE',
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
  INTERNAL: 'INTERNAL',
} as const;
export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];

export interface ErrorDetail {
  path: string;
  message: string;
}

export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: ErrorCode,
    message: string,
    public readonly details?: ErrorDetail[],
    options?: { cause?: unknown },
  ) {
    super(message, options);
    this.name = 'AppError';
  }
}

export const unauthenticated = () =>
  new AppError(401, ErrorCode.UNAUTHENTICATED, 'Authentication required.');

export const invalidToken = (cause?: unknown) =>
  new AppError(401, ErrorCode.INVALID_TOKEN, 'Your session is invalid or has expired. Please sign in again.', undefined, {
    cause,
  });

export const authUnavailable = (cause?: unknown) =>
  new AppError(503, ErrorCode.SERVICE_UNAVAILABLE, 'Service temporarily unavailable. Please try again.', undefined, {
    cause,
  });

export const validationError = (details: ErrorDetail[]) =>
  new AppError(400, ErrorCode.VALIDATION_ERROR, 'The request is invalid.', details);
