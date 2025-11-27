import type { Socket } from 'socket.io';
import type { AuthenticatedSocket } from '../types/socket.types';
import authService from '../../services/auth.service';
import userRepository from '../../repositories/userRepository';
import { UserStatus } from '../../database/types';
import Logger from '../../config/logger';

interface JWTPayload {
  userId: string;
  email: string;
}

export class SocketAuthMiddleware {
  /**
   * Middleware to authenticate socket connections.
   * Extracts JWT access token from handshake auth, headers, or query params.
   */
  authenticate = async (socket: Socket, next: (err?: Error) => void): Promise<void> => {
    try {
      const token = this.extractToken(socket);

      if (!token) {
        Logger.warn('Socket connection attempted without token', {
          socketId: socket.id,
          ip: socket.handshake.address,
        });
        next(new Error('Authentication token required'));
        return;
      }

      const decoded = await this.verifyToken(token);

      if (!decoded) {
        Logger.warn('Invalid token provided for socket connection', {
          socketId: socket.id,
        });
        next(new Error('Invalid authentication token'));
        return;
      }

      const user = await userRepository.findById(decoded.userId);

      if (!user) {
        Logger.warn('User not found for socket connection', {
          socketId: socket.id,
          userId: decoded.userId,
        });
        next(new Error('User not found'));
        return;
      }

      if (user.status !== UserStatus.ACTIVE) {
        Logger.warn('Inactive user attempted socket connection', {
          socketId: socket.id,
          userId: decoded.userId,
          status: user.status,
        });
        next(new Error('Account is not active'));
        return;
      }

      const phoneNumbers: string[] = [];
      if (user.phone_number) {
        phoneNumbers.push(user.phone_number);
      }

      const authenticatedSocket = socket as AuthenticatedSocket;
      const now = new Date();

      authenticatedSocket.user = {
        userId: user.id,
        email: user.email,
        phoneNumbers,
        connectedAt: now,
        lastActivity: now,
      };

      Logger.info('Socket authenticated successfully', {
        socketId: socket.id,
        userId: user.id,
        email: user.email,
      });

      next();
    } catch (error) {
      Logger.error('Socket authentication error', {
        socketId: socket.id,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      next(new Error('Authentication failed'));
    }
  };

  /**
   * Extract token from socket handshake.
   */
  private extractToken(socket: Socket): string | null {
    if (socket.handshake.auth?.token) {
      return socket.handshake.auth.token as string;
    }

    const authHeader = socket.handshake.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    if (socket.handshake.query?.token) {
      return socket.handshake.query.token as string;
    }

    return null;
  }

  /**
   * Verify JWT access token using existing auth service.
   */
  private async verifyToken(token: string): Promise<JWTPayload | null> {
    try {
      const payload = authService.verifyAccessToken(token);
      return {
        userId: payload.userId,
        email: payload.email,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      Logger.debug('Socket token verification failed', { message });
      return null;
    }
  }

  /**
   * Refresh authentication (can be called during connection).
   */
  async refreshAuth(socket: AuthenticatedSocket, newToken: string): Promise<boolean> {
    const decoded = await this.verifyToken(newToken);

    if (!decoded || decoded.userId !== socket.user.userId) {
      return false;
    }

    socket.user.lastActivity = new Date();
    return true;
  }
}

export const socketAuthMiddleware = new SocketAuthMiddleware();


