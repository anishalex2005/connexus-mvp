import { Response } from 'express';
import {
  AuthenticatedRequest,
  RegisterRequestBody,
  LoginRequestBody,
  RefreshRequestBody,
  AuthResponse,
} from '../types/auth.types';
import authService from '../services/auth.service';
import { userRepository } from '../repositories/userRepository';
import authConfig from '../config/auth.config';

class AuthController {
  /**
   * POST /api/auth/register
   * Register a new user
   */
  async register(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { email, password, firstName, lastName } = req.body as RegisterRequestBody;

      if (!email || !password || !firstName || !lastName) {
        res.status(400).json({
          success: false,
          message: 'All fields are required',
          errors: ['email, password, firstName, and lastName are required'],
        });
        return;
      }

      if (!authService.validateEmail(email)) {
        res.status(400).json({
          success: false,
          message: 'Invalid email format',
        });
        return;
      }

      const passwordValidation = authService.validatePasswordStrength(password);
      if (!passwordValidation.valid) {
        res.status(400).json({
          success: false,
          message: 'Password does not meet requirements',
          errors: passwordValidation.errors,
        });
        return;
      }

      const existingUser = await userRepository.findByEmail(email.toLowerCase());
      if (existingUser) {
        res.status(409).json({
          success: false,
          message: 'An account with this email already exists',
        });
        return;
      }

      const passwordHash = await authService.hashPassword(password);
      const userId = authService.generateUserId();

      const user = await userRepository.create({
        email: email.toLowerCase(),
        password_hash: passwordHash,
        first_name: firstName.trim(),
        last_name: lastName.trim(),
      });

      // Ensure we use the generated UUID (from migration default or our own)
      const id = user.id || userId;
      const tokens = authService.generateTokenPair(id, user.email);

      const response: AuthResponse = {
        success: true,
        message: 'Registration successful',
        data: {
          user: {
            id,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
          },
          tokens: {
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: authConfig.jwt.accessExpiry,
          },
        },
      };

      res.status(201).json(response);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'An error occurred during registration',
      });
    }
  }

  /**
   * POST /api/auth/login
   * Authenticate user and return tokens
   */
  async login(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { email, password } = req.body as LoginRequestBody;

      if (!email || !password) {
        res.status(400).json({
          success: false,
          message: 'Email and password are required',
        });
        return;
      }

      const user = await userRepository.findByEmail(email.toLowerCase());
      if (!user) {
        res.status(401).json({
          success: false,
          message: 'Invalid email or password',
        });
        return;
      }

      const isValidPassword = await authService.verifyPassword(password, user.password_hash);
      if (!isValidPassword) {
        res.status(401).json({
          success: false,
          message: 'Invalid email or password',
        });
        return;
      }

      const tokens = authService.generateTokenPair(user.id, user.email);
      await userRepository.updateLastLogin(user.id);

      const response: AuthResponse = {
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
          },
          tokens: {
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: authConfig.jwt.accessExpiry,
          },
        },
      };

      res.status(200).json(response);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'An error occurred during login',
      });
    }
  }

  /**
   * POST /api/auth/refresh
   * Refresh access token using refresh token
   */
  async refreshToken(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body as RefreshRequestBody;

      if (!refreshToken) {
        res.status(400).json({
          success: false,
          message: 'Refresh token is required',
        });
        return;
      }

      const payload = authService.verifyRefreshToken(refreshToken);
      const user = await userRepository.findById(payload.userId);

      if (!user) {
        res.status(401).json({
          success: false,
          message: 'User not found',
        });
        return;
      }

      const tokens = authService.generateTokenPair(user.id, user.email);

      res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: {
          tokens: {
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: authConfig.jwt.accessExpiry,
          },
        },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Token refresh failed';
      res.status(401).json({
        success: false,
        message,
      });
    }
  }

  /**
   * POST /api/auth/logout
   * Logout user (client should discard tokens)
   * For enhanced security, implement token blacklisting in production
   */
  async logout(_req: AuthenticatedRequest, res: Response): Promise<void> {
    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  }

  /**
   * GET /api/auth/me
   * Get current authenticated user's profile
   */
  async getCurrentUser(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.authUser) {
        res.status(401).json({
          success: false,
          message: 'Not authenticated',
        });
        return;
      }

      const user = await userRepository.findById(req.authUser.userId);
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found',
        });
        return;
      }

      res.status(200).json({
        success: true,
        message: 'User retrieved successfully',
        data: {
          user: {
            id: user.id,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
            createdAt: user.created_at,
          },
        },
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Get current user error:', error);
      res.status(500).json({
        success: false,
        message: 'An error occurred while fetching user data',
      });
    }
  }
}

export const authController = new AuthController();
export default authController;


