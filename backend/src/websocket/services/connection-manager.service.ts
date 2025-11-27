import type { Server } from 'socket.io';
import type { AuthenticatedSocket } from '../types/socket.types';
import Logger from '../../config/logger';

interface ConnectionInfo {
  socketId: string;
  userId: string;
  connectedAt: Date;
  lastActivity: Date;
  ip: string;
  userAgent: string;
}

export class ConnectionManager {
  private io: Server;
  private userConnections: Map<string, Set<string>> = new Map();
  private connections: Map<string, ConnectionInfo> = new Map();

  constructor(io: Server) {
    this.io = io;
  }

  /**
   * Register a new connection.
   */
  registerConnection(socket: AuthenticatedSocket): void {
    const connectionInfo: ConnectionInfo = {
      socketId: socket.id,
      userId: socket.user.userId,
      connectedAt: new Date(),
      lastActivity: new Date(),
      ip: socket.handshake.address,
      userAgent: (socket.handshake.headers['user-agent'] as string) || 'unknown',
    };

    this.connections.set(socket.id, connectionInfo);

    if (!this.userConnections.has(socket.user.userId)) {
      this.userConnections.set(socket.user.userId, new Set());
    }
    this.userConnections.get(socket.user.userId)!.add(socket.id);

    Logger.info('Connection registered', {
      socketId: socket.id,
      userId: socket.user.userId,
      totalUserConnections: this.userConnections.get(socket.user.userId)!.size,
    });
  }

  /**
   * Unregister a connection.
   */
  unregisterConnection(socket: AuthenticatedSocket): void {
    const userId = socket.user.userId;

    this.connections.delete(socket.id);

    const userSockets = this.userConnections.get(userId);
    if (userSockets) {
      userSockets.delete(socket.id);
      if (userSockets.size === 0) {
        this.userConnections.delete(userId);
      }
    }

    Logger.info('Connection unregistered', {
      socketId: socket.id,
      userId,
      remainingConnections: userSockets?.size || 0,
    });
  }

  /**
   * Update last activity for a connection.
   */
  updateActivity(socketId: string): void {
    const connection = this.connections.get(socketId);
    if (connection) {
      connection.lastActivity = new Date();
    }
  }

  /**
   * Check if user is online (has at least one connection).
   */
  isUserOnline(userId: string): boolean {
    const connections = this.userConnections.get(userId);
    return connections !== undefined && connections.size > 0;
  }

  /**
   * Get all socket IDs for a user.
   */
  getUserSocketIds(userId: string): string[] {
    const connections = this.userConnections.get(userId);
    return connections ? Array.from(connections) : [];
  }

  /**
   * Get connection info.
   */
  getConnectionInfo(socketId: string): ConnectionInfo | null {
    return this.connections.get(socketId) || null;
  }

  /**
   * Get socket by ID.
   */
  getSocket(socketId: string): AuthenticatedSocket | null {
    const socket = this.io.sockets.sockets.get(socketId);
    return (socket as AuthenticatedSocket | undefined) || null;
  }

  /**
   * Get all sockets for a user.
   */
  getUserSockets(userId: string): AuthenticatedSocket[] {
    const socketIds = this.getUserSocketIds(userId);
    const sockets: AuthenticatedSocket[] = [];

    for (const socketId of socketIds) {
      const socket = this.getSocket(socketId);
      if (socket) {
        sockets.push(socket);
      }
    }

    return sockets;
  }

  /**
   * Disconnect all connections for a user.
   */
  disconnectUser(userId: string, reason: string = 'forced_disconnect'): void {
    const sockets = this.getUserSockets(userId);

    for (const socket of sockets) {
      socket.emit('connection:error', {
        code: 'FORCED_DISCONNECT',
        message: reason,
      });
      socket.disconnect(true);
    }

    Logger.info('User forcefully disconnected', {
      userId,
      reason,
      disconnectedSockets: sockets.length,
    });
  }

  /**
   * Get connection statistics.
   */
  getStats(): {
    totalConnections: number;
    uniqueUsers: number;
    connectionsByUser: Map<string, number>;
  } {
    const connectionsByUser = new Map<string, number>();

    for (const [userId, sockets] of this.userConnections) {
      connectionsByUser.set(userId, sockets.size);
    }

    return {
      totalConnections: this.connections.size,
      uniqueUsers: this.userConnections.size,
      connectionsByUser,
    };
  }

  /**
   * Clean up stale connections (connections with no recent activity).
   */
  cleanupStaleConnections(maxInactivityMs: number = 5 * 60 * 1000): number {
    const now = Date.now();
    let cleanedCount = 0;

    for (const [socketId, connection] of this.connections) {
      const inactiveTime = now - connection.lastActivity.getTime();

      if (inactiveTime > maxInactivityMs) {
        const socket = this.getSocket(socketId);
        if (socket) {
          socket.emit('connection:error', {
            code: 'INACTIVITY_TIMEOUT',
            message: 'Connection closed due to inactivity',
          });
          socket.disconnect(true);
          cleanedCount++;
        }
      }
    }

    if (cleanedCount > 0) {
      Logger.info('Cleaned up stale connections', { count: cleanedCount });
    }

    return cleanedCount;
  }
}


