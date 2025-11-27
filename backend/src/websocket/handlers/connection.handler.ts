import type { AuthenticatedSocket, PresenceStatus } from '../types/socket.types';
import { RoomType } from '../types/socket.types';
import { ConnectionManager } from '../services/connection-manager.service';
import { RoomManager } from '../services/room-manager.service';
import { socketAuthMiddleware } from '../middleware/socket-auth.middleware';
import Logger from '../../config/logger';
import { v4 as uuidv4 } from 'uuid';

export class ConnectionHandler {
  constructor(
    private connectionManager: ConnectionManager,
    private roomManager: RoomManager,
  ) {}

  /**
   * Set up connection event handlers.
   */
  setupHandlers(socket: AuthenticatedSocket): void {
    this.connectionManager.registerConnection(socket);

    void this.roomManager.joinUserRoom(socket);

    socket.emit('connection:established', {
      connectionId: uuidv4(),
      serverTime: new Date(),
      user: socket.user,
    });

    this.setupAuthHandlers(socket);
    this.setupPresenceHandlers(socket);
    this.setupRoomHandlers(socket);
    this.setupPingHandler(socket);
    this.setupDisconnectHandler(socket);

    Logger.info('Socket handlers set up', {
      socketId: socket.id,
      userId: socket.user.userId,
    });
  }

  /**
   * Authentication handlers.
   */
  private setupAuthHandlers(socket: AuthenticatedSocket): void {
    socket.on('auth:authenticate', async (token, callback) => {
      const success = await socketAuthMiddleware.refreshAuth(socket, token);
      callback({
        success,
        message: success ? 'Authentication refreshed' : 'Authentication failed',
        user: success ? socket.user : undefined,
      });
    });

    socket.on('auth:refresh', async (token, callback) => {
      const success = await socketAuthMiddleware.refreshAuth(socket, token);
      callback({
        success,
        message: success ? 'Token refreshed' : 'Token refresh failed',
        user: success ? socket.user : undefined,
      });
    });
  }

  /**
   * Presence handlers.
   */
  private setupPresenceHandlers(socket: AuthenticatedSocket): void {
    socket.on('presence:update', (status: PresenceStatus) => {
      this.connectionManager.updateActivity(socket.id);

      const presenceData = {
        userId: socket.user.userId,
        status,
        timestamp: new Date(),
      };

      socket.broadcast.emit('presence:changed', presenceData);

      Logger.debug('Presence updated', {
        userId: socket.user.userId,
        status: status.status,
      });
    });

    socket.on('presence:typing', (data) => {
      socket.to(data.roomId).emit('presence:typing', {
        ...data,
        userId: socket.user.userId,
      });
    });
  }

  /**
   * Room handlers.
   */
  private setupRoomHandlers(socket: AuthenticatedSocket): void {
    socket.on('room:join', async (roomId, callback) => {
      try {
        const type: RoomType = roomId.startsWith('call:')
          ? RoomType.CALL
          : roomId.startsWith('phone:')
            ? RoomType.PHONE
            : RoomType.USER;

        const success = await this.roomManager.joinRoom(socket, roomId, type);

        if (success) {
          const participants = this.roomManager.getRoomParticipants(roomId);
          callback({
            success: true,
            roomId,
            participants,
          });
        } else {
          callback({
            success: false,
            error: 'Failed to join room',
          });
        }
      } catch (error) {
        Logger.error('Room join error', {
          userId: socket.user.userId,
          roomId,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
        callback({
          success: false,
          error: 'Room join error',
        });
      }
    });

    socket.on('room:leave', async (roomId) => {
      await this.roomManager.leaveRoom(socket, roomId);
    });
  }

  /**
   * Ping handler for connection health monitoring.
   */
  private setupPingHandler(socket: AuthenticatedSocket): void {
    socket.on('ping', (callback) => {
      this.connectionManager.updateActivity(socket.id);
      callback(Date.now());
    });
  }

  /**
   * Disconnect handler.
   */
  private setupDisconnectHandler(socket: AuthenticatedSocket): void {
    socket.on('disconnect', async (reason) => {
      Logger.info('Socket disconnected', {
        socketId: socket.id,
        userId: socket.user.userId,
        reason,
      });

      await this.roomManager.leaveAllRooms(socket);

      this.connectionManager.unregisterConnection(socket);

      if (!this.connectionManager.isUserOnline(socket.user.userId)) {
        socket.broadcast.emit('presence:changed', {
          userId: socket.user.userId,
          status: { status: 'offline' },
          timestamp: new Date(),
        });
      }
    });
  }
}


