import { Request } from 'express';

// User payload stored in JWT
export interface JwtPayload {
  userId: string;
  email: string;
  type: 'access' | 'refresh';
  iat?: number;
  exp?: number;
}

// Extended Express Request with auth user info
export interface AuthenticatedRequest extends Request {
  authUser?: JwtPayload;
}

// Registration request body
export interface RegisterRequestBody {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

// Login request body
export interface LoginRequestBody {
  email: string;
  password: string;
}

// Token refresh request body
export interface RefreshRequestBody {
  refreshToken: string;
}

// Auth response with tokens
export interface AuthResponse {
  success: boolean;
  message: string;
  data?: {
    user: {
      id: string;
      email: string;
      firstName: string | null;
      lastName: string | null;
    };
    tokens: {
      accessToken: string;
      refreshToken: string;
      expiresIn: string;
    };
  };
}

// Generic API response
export interface ApiResponse<T = unknown> {
  success: boolean;
  message: string;
  data?: T;
  errors?: string[];
}


