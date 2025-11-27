import dotenv from 'dotenv';
import path from 'path';

// Ensure environment variables are loaded (same .env path as main config)
dotenv.config({ path: path.join(__dirname, '../../.env') });

export interface AuthConfig {
  jwt: {
    accessSecret: string;
    refreshSecret: string;
    accessExpiry: string;
    refreshExpiry: string;
  };
  bcrypt: {
    rounds: number;
  };
}

const authConfig: AuthConfig = {
  jwt: {
    accessSecret:
      process.env.JWT_ACCESS_SECRET || 'fallback-access-secret-change-in-production',
    refreshSecret:
      process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret-change-in-production',
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },
  bcrypt: {
    rounds: parseInt(process.env.BCRYPT_ROUNDS || '12', 10),
  },
};

// Basic validation – in production we must have real secrets
if (process.env.NODE_ENV === 'production') {
  if (!process.env.JWT_ACCESS_SECRET || !process.env.JWT_REFRESH_SECRET) {
    throw new Error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be set in production');
  }
}

export default authConfig;


