import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../types/auth.types';
import authService from '../services/auth.service';

/**
 * Middleware to authenticate requests using JWT access token
 * Expects: Authorization: Bearer <token>
 */
export const authenticateToken = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      res.status(401).json({
        success: false,
        message: 'Authorization header is required',
      });
      return;
    }

    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      res.status(401).json({
        success: false,
        message: 'Authorization header must be in format: Bearer <token>',
      });
      return;
    }

    const token = parts[1];
    const payload = authService.verifyAccessToken(token);

    // Attach auth user info to request
    req.authUser = payload;

    next();
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Authentication failed';

    res.status(401).json({
      success: false,
      message,
    });
  }
};

/**
 * Optional authentication - doesn't fail if no token provided
 * Useful for routes that work with or without authentication
 */
export const optionalAuth = (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader) {
      const parts = authHeader.split(' ');
      if (parts.length === 2 && parts[0] === 'Bearer') {
        const payload = authService.verifyAccessToken(parts[1]);
        req.authUser = payload;
      }
    }

    next();
  } catch {
    // Silently continue without authentication
    next();
  }
};

/**
 * Rate limiting for auth endpoints (basic implementation)
 * For production, use a proper rate limiter like express-rate-limit
 */
const loginAttempts = new Map<string, { count: number; firstAttempt: number }>();

export const rateLimitAuth = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  const ip = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  const windowMs = 15 * 60 * 1000; // 15 minutes
  const maxAttempts = 5;

  const attempts = loginAttempts.get(ip);

  if (attempts) {
    // Reset if window has passed
    if (now - attempts.firstAttempt > windowMs) {
      loginAttempts.set(ip, { count: 1, firstAttempt: now });
      next();
      return;
    }

    // Check if too many attempts
    if (attempts.count >= maxAttempts) {
      res.status(429).json({
        success: false,
        message: 'Too many login attempts. Please try again later.',
      });
      return;
    }

    // Increment count
    attempts.count++;
  } else {
    loginAttempts.set(ip, { count: 1, firstAttempt: now });
  }

  next();
};

// Clean up old entries periodically
setInterval(() => {
  const now = Date.now();
  const windowMs = 15 * 60 * 1000;

  for (const [ip, attempts] of loginAttempts.entries()) {
    if (now - attempts.firstAttempt > windowMs) {
      loginAttempts.delete(ip);
    }
  }
}, 60 * 1000);


