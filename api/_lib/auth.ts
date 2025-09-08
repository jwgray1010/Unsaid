// api/_lib/auth.ts
import { VercelRequest } from '@vercel/node';
import { logger } from './logger';

export interface AuthContext {
  userId: string;
  isAuthenticated: boolean;
  userEmail?: string;
  permissions?: string[];
}

export function extractUserId(req: VercelRequest): string {
  // Try multiple sources for user ID
  const userId = 
    req.headers['x-user-id'] ||
    req.headers['user-id'] ||
    req.query.userId ||
    req.body?.userId ||
    'anonymous';
    
  return userId as string;
}

export function extractUserEmail(req: VercelRequest): string | undefined {
  const email = 
    req.headers['x-user-email'] ||
    req.headers['user-email'] ||
    req.query.email ||
    req.body?.email;
    
  return email as string | undefined;
}

export function getAuthContext(req: VercelRequest): AuthContext {
  const userId = extractUserId(req);
  const userEmail = extractUserEmail(req);
  
  // In a real implementation, you would validate JWT tokens here
  const isAuthenticated = userId !== 'anonymous';
  
  return {
    userId,
    isAuthenticated,
    userEmail,
    permissions: isAuthenticated ? ['basic'] : []
  };
}

export function requireAuth(req: VercelRequest): AuthContext {
  const auth = getAuthContext(req);
  
  if (!auth.isAuthenticated) {
    throw new Error('Authentication required');
  }
  
  return auth;
}

export function requirePermission(req: VercelRequest, permission: string): AuthContext {
  const auth = requireAuth(req);
  
  if (!auth.permissions?.includes(permission) && !auth.permissions?.includes('admin')) {
    throw new Error(`Permission required: ${permission}`);
  }
  
  return auth;
}
