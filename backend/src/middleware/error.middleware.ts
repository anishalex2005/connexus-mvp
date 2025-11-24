import { Request, Response, NextFunction } from 'express';
import Logger from '../config/logger';

export interface ApiError extends Error {
  statusCode?: number;
  status?: string;
  isOperational?: boolean;
}

export class AppError extends Error implements ApiError {
  public readonly statusCode: number;
  public readonly status: string;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export const notFoundHandler = (req: Request, _res: Response, next: NextFunction): void => {
  void _res; // mark as used to satisfy TypeScript noUnusedParameters
  const error = new AppError(`Cannot find ${req.originalUrl} on this server`, 404);
  next(error);
};

export const errorHandler = (err: ApiError, req: Request, res: Response, _next: NextFunction): void => {
  const error: ApiError = { ...err };
  error.message = err.message;

  const statusCode = error.statusCode || 500;
  const status = error.status || 'error';

  Logger.error(`${statusCode} - ${error.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);

  res.status(statusCode).json({
    status,
    statusCode,
    message: error.message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

