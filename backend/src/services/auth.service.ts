import bcrypt from 'bcryptjs';
import jwt, { SignOptions, TokenExpiredError, JsonWebTokenError } from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import authConfig from '../config/auth.config';
import { JwtPayload } from '../types/auth.types';

class AuthService {
  /**
   * Hash a plain text password
   */
  async hashPassword(plainPassword: string): Promise<string> {
    const salt = await bcrypt.genSalt(authConfig.bcrypt.rounds);
    return bcrypt.hash(plainPassword, salt);
  }

  /**
   * Compare plain password with hashed password
   */
  async verifyPassword(plainPassword: string, hashedPassword: string): Promise<boolean> {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Generate access token (short-lived)
   */
  generateAccessToken(userId: string, email: string): string {
    const payload: JwtPayload = {
      userId,
      email,
      type: 'access',
    };

    const options: SignOptions = {
      // jsonwebtoken types allow string expressions like "15m" at runtime
      expiresIn: authConfig.jwt.accessExpiry as unknown as number,
      issuer: 'connexus-api',
      subject: userId,
    };

    return jwt.sign(payload, authConfig.jwt.accessSecret, options);
  }

  /**
   * Generate refresh token (long-lived)
   */
  generateRefreshToken(userId: string, email: string): string {
    const payload: JwtPayload = {
      userId,
      email,
      type: 'refresh',
    };

    const options: SignOptions = {
      // jsonwebtoken types allow string expressions like "7d" at runtime
      expiresIn: authConfig.jwt.refreshExpiry as unknown as number,
      issuer: 'connexus-api',
      subject: userId,
    };

    return jwt.sign(payload, authConfig.jwt.refreshSecret, options);
  }

  /**
   * Generate both access and refresh tokens
   */
  generateTokenPair(userId: string, email: string): { accessToken: string; refreshToken: string } {
    return {
      accessToken: this.generateAccessToken(userId, email),
      refreshToken: this.generateRefreshToken(userId, email),
    };
  }

  /**
   * Verify and decode access token
   */
  verifyAccessToken(token: string): JwtPayload {
    try {
      const decoded = jwt.verify(token, authConfig.jwt.accessSecret, {
        issuer: 'connexus-api',
      }) as JwtPayload;

      if (decoded.type !== 'access') {
        throw new Error('Invalid token type');
      }

      return decoded;
    } catch (error) {
      if (error instanceof TokenExpiredError) {
        throw new Error('Access token has expired');
      }

      if (error instanceof JsonWebTokenError) {
        throw new Error('Invalid access token');
      }

      throw error;
    }
  }

  /**
   * Verify and decode refresh token
   */
  verifyRefreshToken(token: string): JwtPayload {
    try {
      const decoded = jwt.verify(token, authConfig.jwt.refreshSecret, {
        issuer: 'connexus-api',
      }) as JwtPayload;

      if (decoded.type !== 'refresh') {
        throw new Error('Invalid token type');
      }

      return decoded;
    } catch (error) {
      if (error instanceof TokenExpiredError) {
        throw new Error('Refresh token has expired');
      }

      if (error instanceof JsonWebTokenError) {
        throw new Error('Invalid refresh token');
      }

      throw error;
    }
  }

  /**
   * Validate password strength
   */
  validatePasswordStrength(password: string): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (password.length < 8) {
      errors.push('Password must be at least 8 characters long');
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }
    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }
    if (!/[0-9]/.test(password)) {
      errors.push('Password must contain at least one number');
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      errors.push('Password must contain at least one special character');
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validate email format
   */
  validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Generate a unique user ID
   */
  generateUserId(): string {
    return uuidv4();
  }
}

// Export singleton instance
export const authService = new AuthService();
export default authService;


