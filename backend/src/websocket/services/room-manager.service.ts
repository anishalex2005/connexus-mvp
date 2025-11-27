import type { Server } from 'socket.io';
import type { AuthenticatedSocket } from '../types/socket.types';
import { RoomType } from '../types/socket.types';
import Logger from '../../config/logger';

interface RoomInfo {
  id: string;
  type: RoomType;
  participants: Set<string>;
  metadata: Record<string, unknown>;
  createdAt: Date;
}

export class RoomManager {
  private io: Server;
  private rooms: Map<string, RoomInfo> = new Map();

  constructor(io: Server) {
    this.io = io;
  }

  /**
   * Generate room ID based on type.
   */
  generateRoomId(type: RoomType, identifier: string): string {
    return `${type}:${identifier}`;
  }

  /**
   * Join a user to their personal room (auto-joined on connect),
   * and phone-number-specific rooms.
   */
  async joinUserRoom(socket: AuthenticatedSocket): Promise<void> {
    const userRoomId = this.generateRoomId(RoomType.USER, socket.user.userId);
    await this.joinRoom(socket, userRoomId, RoomType.USER);

    for (const phoneNumber of socket.user.phoneNumbers) {
      const phoneRoomId = this.generateRoomId(RoomType.PHONE, phoneNumber);
      await this.joinRoom(socket, phoneRoomId, RoomType.PHONE);
    }
  }

  /**
   * Join a socket to a room.
   */
  async joinRoom(
    socket: AuthenticatedSocket,
    roomId: string,
    type: RoomType,
    metadata: Record<string, unknown> = {},
  ): Promise<boolean> {
    try {
      if (!this.rooms.has(roomId)) {
        this.rooms.set(roomId, {
          id: roomId,
          type,
          participants: new Set(),
          metadata,
          createdAt: new Date(),
        });
      }

      const room = this.rooms.get(roomId)!;

      room.participants.add(socket.user.userId);

      await socket.join(roomId);

      Logger.debug('User joined room', {
        userId: socket.user.userId,
        roomId,
        type,
        participantCount: room.participants.size,
      });

      return true;
    } catch (error) {
      Logger.error('Error joining room', {
        userId: socket.user.userId,
        roomId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return false;
    }
  }

  /**
   * Leave a room.
   */
  async leaveRoom(socket: AuthenticatedSocket, roomId: string): Promise<void> {
    try {
      const room = this.rooms.get(roomId);

      if (room) {
        room.participants.delete(socket.user.userId);

        if (room.participants.size === 0 && room.type !== RoomType.BROADCAST) {
          this.rooms.delete(roomId);
        }
      }

      await socket.leave(roomId);

      Logger.debug('User left room', {
        userId: socket.user.userId,
        roomId,
      });
    } catch (error) {
      Logger.error('Error leaving room', {
        userId: socket.user.userId,
        roomId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Leave all rooms for a socket.
   */
  async leaveAllRooms(socket: AuthenticatedSocket): Promise<void> {
    const socketRooms = Array.from(socket.rooms);

    for (const roomId of socketRooms) {
      if (roomId !== socket.id) {
        await this.leaveRoom(socket, roomId);
      }
    }
  }

  /**
   * Get room information.
   */
  getRoomInfo(roomId: string): RoomInfo | null {
    return this.rooms.get(roomId) || null;
  }

  /**
   * Get all rooms for a user.
   */
  getUserRooms(userId: string): string[] {
    const userRooms: string[] = [];

    for (const [roomId, room] of this.rooms) {
      if (room.participants.has(userId)) {
        userRooms.push(roomId);
      }
    }

    return userRooms;
  }

  /**
   * Get all participants in a room.
   */
  getRoomParticipants(roomId: string): string[] {
    const room = this.rooms.get(roomId);
    return room ? Array.from(room.participants) : [];
  }

  /**
   * Create a call room.
   */
  async createCallRoom(
    callId: string,
    participants: AuthenticatedSocket[],
    metadata: Record<string, unknown> = {},
  ): Promise<string> {
    const roomId = this.generateRoomId(RoomType.CALL, callId);

    for (const socket of participants) {
      await this.joinRoom(socket, roomId, RoomType.CALL, {
        ...metadata,
        callId,
      });
    }

    Logger.info('Call room created', {
      roomId,
      callId,
      participantCount: participants.length,
    });

    return roomId;
  }

  /**
   * End a call room.
   */
  async endCallRoom(callId: string): Promise<void> {
    const roomId = this.generateRoomId(RoomType.CALL, callId);
    const room = this.rooms.get(roomId);

    if (room) {
      this.io.to(roomId).emit('call:ended', {
        callId,
        reason: 'completed',
        duration: Date.now() - room.createdAt.getTime(),
        timestamp: new Date(),
      });

      this.rooms.delete(roomId);

      Logger.info('Call room ended', { roomId, callId });
    }
  }

  /**
   * Broadcast to a room.
   */
  broadcastToRoom<T>(roomId: string, event: string, data: T): void {
    this.io.to(roomId).emit(event as any, data);
  }

  /**
   * Send to specific user.
   */
  sendToUser<T>(userId: string, event: string, data: T): void {
    const roomId = this.generateRoomId(RoomType.USER, userId);
    this.io.to(roomId).emit(event as any, data);
  }

  /**
   * Get room statistics.
   */
  getStats(): {
    totalRooms: number;
    roomsByType: Record<RoomType, number>;
    totalParticipants: number;
  } {
    const stats = {
      totalRooms: this.rooms.size,
      roomsByType: {
        [RoomType.USER]: 0,
        [RoomType.CALL]: 0,
        [RoomType.PHONE]: 0,
        [RoomType.BROADCAST]: 0,
      } as Record<RoomType, number>,
      totalParticipants: 0,
    };

    for (const room of this.rooms.values()) {
      stats.roomsByType[room.type]++;
      stats.totalParticipants += room.participants.size;
    }

    return stats;
  }
}


