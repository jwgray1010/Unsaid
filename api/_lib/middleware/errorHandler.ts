// api/_lib/middleware/errorHandler.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { ZodError } from 'zod';
import { logger } from '../logger';
import { env } from '../env';

// Custom Error Classes
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number = 500, code: string = 'ERR_UNKNOWN', isOperational: boolean = true) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
  }
}

export class AppValidationError extends AppError {
  public readonly details?: any;

  constructor(message: string = 'Validation failed', details?: any) {
    super(message, 400, 'ERR_VALIDATION');
    this.details = details;
  }
}

export class AppNotFoundError extends AppError {
  constructor(message: string = 'Resource not found') {
    super(message, 404, 'ERR_NOT_FOUND');
  }
}

export class AppUnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized access') {
    super(message, 401, 'ERR_UNAUTHORIZED');
  }
}

export class AppForbiddenError extends AppError {
  constructor(message: string = 'Access forbidden') {
    super(message, 403, 'ERR_FORBIDDEN');
  }
}

export class AppTooManyRequestsError extends AppError {
  constructor(message: string = 'Too many requests') {
    super(message, 429, 'ERR_TOO_MANY_REQUESTS');
  }
}

// Zod error formatter
function formatZodError(error: ZodError): { message: string; details: any[] } {
  const details = error.errors.map(err => ({
    field: err.path.join('.'),
    message: err.message,
    code: err.code,
    received: err.code === 'invalid_type' ? (err as any).received : undefined
  }));

  return {
    message: 'Validation failed',
    details
  };
}

// Main error handler
export function handleError(err: any, req: VercelRequest, res: VercelResponse): void {
  // Generate request ID if not present
  const reqId = (req as any).id || `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Base error response
  const baseResponse = {
    success: false,
    reqId,
    timestamp: new Date().toISOString()
  };

  let statusCode = 500;
  let responsePayload: any = {
    ...baseResponse,
    error: 'Internal Server Error',
    code: 'ERR_INTERNAL'
  };

  // Handle different error types
  if (err instanceof AppError) {
    // Custom application errors
    statusCode = err.statusCode;
    responsePayload = {
      ...baseResponse,
      error: err.message,
      code: err.code
    };

    if (err instanceof AppValidationError && err.details) {
      responsePayload.details = err.details;
    }

  } else if (err instanceof ZodError) {
    // Zod validation errors
    statusCode = 400;
    const formatted = formatZodError(err);
    responsePayload = {
      ...baseResponse,
      error: formatted.message,
      code: 'ERR_VALIDATION',
      details: formatted.details
    };

  } else if (err.name === 'ValidationError') {
    // Generic validation errors
    statusCode = 400;
    responsePayload = {
      ...baseResponse,
      error: err.message || 'Validation failed',
      code: 'ERR_VALIDATION'
    };

  } else if (err.code === 'ENOTFOUND' || err.code === 'ECONNREFUSED') {
    // Network errors
    statusCode = 503;
    responsePayload = {
      ...baseResponse,
      error: 'Service temporarily unavailable',
      code: 'ERR_SERVICE_UNAVAILABLE'
    };

  } else if (err.name === 'JsonWebTokenError') {
    // JWT errors
    statusCode = 401;
    responsePayload = {
      ...baseResponse,
      error: 'Invalid authentication token',
      code: 'ERR_INVALID_TOKEN'
    };

  } else if (err.name === 'TokenExpiredError') {
    // Expired JWT
    statusCode = 401;
    responsePayload = {
      ...baseResponse,
      error: 'Authentication token expired',
      code: 'ERR_TOKEN_EXPIRED'
    };
  }

  // Include stack trace in development
  if (env.NODE_ENV !== 'production' && err.stack) {
    responsePayload.stack = err.stack.split('\n');
  }

  // Log error with context
  const logContext = {
    reqId,
    method: req.method,
    url: req.url,
    status: statusCode,
    code: responsePayload.code,
    userAgent: req.headers['user-agent'],
    ip: req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || 'unknown',
    error: {
      name: err.name,
      message: err.message,
      stack: err.stack
    }
  };

  if (statusCode >= 500) {
    logger.error('Server error occurred', logContext);
  } else if (statusCode >= 400) {
    logger.warn('Client error occurred', logContext);
  }

  // Send error response
  res.status(statusCode).json(responsePayload);
}

// Error wrapper for async functions
export function withErrorHandling<T extends any[], R>(
  fn: (...args: T) => Promise<R>
): (...args: T) => Promise<R | void> {
  return async (...args: T): Promise<R | void> => {
    try {
      return await fn(...args);
    } catch (error) {
      // This would need the req/res context, so we'll rethrow
      throw error;
    }
  };
}

// Middleware wrapper that includes error handling
export function withErrorMiddleware(handler: (req: VercelRequest, res: VercelResponse) => Promise<void>): (req: VercelRequest, res: VercelResponse) => Promise<void> {
  return async (req: VercelRequest, res: VercelResponse): Promise<void> => {
    try {
      await handler(req, res);
    } catch (error) {
      handleError(error, req, res);
    }
  };
}
