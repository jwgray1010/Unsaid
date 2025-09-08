// api/_lib/http.ts
import { VercelRequest, VercelResponse } from '@vercel/node';

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  timestamp: string;
  version: string;
}

export function json<T>(res: VercelResponse, data: T, status = 200): void {
  const response: ApiResponse<T> = {
    success: status < 400,
    data: status < 400 ? data : undefined,
    error: status >= 400 ? (typeof data === 'string' ? data : 'An error occurred') : undefined,
    message: status >= 400 ? (typeof data === 'object' && data && 'message' in data ? String(data.message) : undefined) : undefined,
    timestamp: new Date().toISOString(),
    version: 'v1'
  };
  
  res.status(status).json(response);
}

export function success<T>(res: VercelResponse, data: T, status = 200): void {
  json(res, data, status);
}

export function error(res: VercelResponse, message: string, status = 500): void {
  json(res, { message }, status);
}

export function badRequest(res: VercelResponse, message: string): void {
  error(res, message, 400);
}

export function unauthorized(res: VercelResponse, message = 'Unauthorized'): void {
  error(res, message, 401);
}

export function forbidden(res: VercelResponse, message = 'Forbidden'): void {
  error(res, message, 403);
}

export function notFound(res: VercelResponse, message = 'Not found'): void {
  error(res, message, 404);
}

export function methodNotAllowed(res: VercelResponse, allowed: string[] = []): void {
  res.setHeader('Allow', allowed.join(', '));
  error(res, `Method not allowed. Allowed methods: ${allowed.join(', ')}`, 405);
}

export function tooManyRequests(res: VercelResponse, message = 'Too many requests'): void {
  error(res, message, 429);
}

export function internalError(res: VercelResponse, message = 'Internal server error'): void {
  error(res, message, 500);
}

export function parseBody<T>(req: VercelRequest): Promise<T> {
  return new Promise((resolve, reject) => {
    if (req.method === 'GET') {
      resolve({} as T);
      return;
    }

    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const parsed = body ? JSON.parse(body) : {};
        resolve(parsed as T);
      } catch (err) {
        reject(new Error('Invalid JSON'));
      }
    });

    req.on('error', (err) => {
      reject(err);
    });
  });
}
