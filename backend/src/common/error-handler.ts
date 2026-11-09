import type { FastifyError, FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { ZodError } from 'zod';
import { AppError, ErrorCode, type ErrorDetail } from './errors.js';

export interface ErrorBody {
  error: {
    code: ErrorCode;
    message: string;
    details?: ErrorDetail[];
    requestId: string;
  };
}

/** Maps framework (Fastify / plugin) 4xx errors to a safe code + generic message. */
function fromFrameworkError(err: FastifyError): AppError | undefined {
  const status = err.statusCode;
  if (!status || status < 400 || status >= 500) return undefined;
  switch (status) {
    case 404:
      return new AppError(404, ErrorCode.NOT_FOUND, 'Not found.');
    case 413:
      return new AppError(413, ErrorCode.PAYLOAD_TOO_LARGE, 'The request body is too large.');
    case 415:
      return new AppError(415, ErrorCode.UNSUPPORTED_MEDIA_TYPE, 'Unsupported content type.');
    case 429:
      return new AppError(429, ErrorCode.RATE_LIMITED, 'Too many requests. Please slow down.');
    default:
      // Malformed JSON, empty body with JSON content type, etc.
      return new AppError(400, ErrorCode.BAD_REQUEST, 'The request could not be processed.');
  }
}

export function toAppError(err: unknown): AppError {
  if (err instanceof AppError) return err;
  if (err instanceof ZodError) {
    return new AppError(
      400,
      ErrorCode.VALIDATION_ERROR,
      'The request is invalid.',
      err.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
    );
  }
  const framework = fromFrameworkError(err as FastifyError);
  if (framework) return framework;
  return new AppError(500, ErrorCode.INTERNAL, 'Something went wrong. Please try again.', undefined, {
    cause: err,
  });
}

function send(request: FastifyRequest, reply: FastifyReply, error: AppError) {
  const body: ErrorBody = {
    error: {
      code: error.code,
      message: error.message,
      ...(error.details?.length ? { details: error.details } : {}),
      requestId: request.id,
    },
  };
  return reply.status(error.statusCode).send(body);
}

/**
 * Centralized error handling. Clients only ever see `ErrorBody`; stack traces,
 * upstream messages and infrastructure details are logged, never returned.
 */
export function registerErrorHandling(app: FastifyInstance) {
  app.setErrorHandler((err, request, reply) => {
    const appError = toAppError(err);
    if (appError.statusCode >= 500) {
      request.log.error({ err: appError.cause ?? err, code: appError.code }, 'request failed');
    } else {
      request.log.info({ code: appError.code, statusCode: appError.statusCode }, 'request rejected');
    }
    return send(request, reply, appError);
  });

  app.setNotFoundHandler((request, reply) =>
    send(request, reply, new AppError(404, ErrorCode.NOT_FOUND, 'Not found.')),
  );
}
