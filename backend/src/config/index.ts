import dotenv from 'dotenv';
import path from 'path';

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../../.env') });

export interface Config {
  env: string;
  port: number;
  apiVersion: string;
  apiPrefix: string;
  cors: {
    origin: string[];
    credentials: boolean;
  };
  rateLimit: {
    windowMs: number;
    max: number;
  };
  jwt: {
    secret: string;
    expiresIn: string;
  };
  database: {
    host: string;
    port: number;
    name: string;
    user: string;
    password: string;
    poolMin: number;
    poolMax: number;
  };
  logging: {
    level: string;
    format: string;
  };
  services: {
    telnyx: {
      apiKey: string;
    };
    retell: {
      apiKey: string;
    };
  };
}

const config: Config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  apiVersion: process.env.API_VERSION || 'v1',
  apiPrefix: process.env.API_PREFIX || '/api',
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
    credentials: true,
  },
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'change-this-secret-in-production',
    expiresIn: '7d',
  },
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    name: process.env.DB_NAME || 'connexus_development',
    user: process.env.DB_USER || 'connexus_dev',
    password: process.env.DB_PASSWORD || 'connexus_dev_password',
    poolMin: parseInt(process.env.DB_POOL_MIN || '2', 10),
    poolMax: parseInt(process.env.DB_POOL_MAX || '10', 10),
  },
  logging: {
    level: process.env.LOG_LEVEL || 'debug',
    format: process.env.LOG_FORMAT || 'combined',
  },
  services: {
    telnyx: {
      apiKey: process.env.TELNYX_API_KEY || '',
    },
    retell: {
      apiKey: process.env.RETELL_API_KEY || '',
    },
  },
};

// Validate critical configuration
if (config.env === 'production') {
  if (config.jwt.secret === 'change-this-secret-in-production') {
    throw new Error('JWT_SECRET must be set in production');
  }
}

export default config;

