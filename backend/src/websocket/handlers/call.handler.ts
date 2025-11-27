import type { AuthenticatedSocket, CallInitiateData } from '../types/socket.types';
import { RoomType } from '../types/socket.types';
import { RoomManager } from '../services/room-manager.service';
import Logger from '../../config/logger';
import { v4 as uuidv4 } from 'uuid';

export class CallHandler {
  constructor(
    private roomManager: RoomManager,
  ) {}

  /**
   * Set up call event handlers.
   */
  setupHandlers(socket: AuthenticatedSocket): void {
    this.setupInitiateHandler(socket);
    this.setupAnswerHandler(socket);
    this.setupRejectHandler(socket);
    this.setupHangupHandler(socket);
    this.setupCallControlHandlers(socket);
  }

  /**
   * Handle call initiation.
   * Note: In production, this integrates with Telnyx (future tasks).
   */
  private setupInitiateHandler(socket: AuthenticatedSocket): void {
    socket.on('call:initiate', async (data: CallInitiateData, callback) => {
      try {
        if (!socket.user.phoneNumbers.includes(data.fromNumber)) {
          callback({
            success: false,
            error: 'Invalid from number',
          });
          return;
        }

        const callId = uuidv4();

        await this.roomManager.createCallRoom(callId, [socket], {
          initiator: socket.user.userId,
          toNumber: data.toNumber,
          fromNumber: data.fromNumber,
          startTime: new Date(),
        });

        socket.emit('call:state_changed', {
          callId,
          state: 'connecting',
          metadata: { toNumber: data.toNumber },
        });

        Logger.info('Call initiated', {
          callId,
          userId: socket.user.userId,
          toNumber: data.toNumber,
        });

        callback({
          success: true,
          callId,
        });
      } catch (error) {
        Logger.error('Call initiation failed', {
          userId: socket.user.userId,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
        callback({
          success: false,
          error: 'Failed to initiate call',
        });
      }
    });
  }

  /**
   * Handle call answer.
   */
  private setupAnswerHandler(socket: AuthenticatedSocket): void {
    socket.on('call:answer', async (callId, callback) => {
      try {
        const roomId = this.roomManager.generateRoomId(RoomType.CALL, callId);
        const roomInfo = this.roomManager.getRoomInfo(roomId);

        if (!roomInfo) {
          callback({
            success: false,
            error: 'Call not found',
          });
          return;
        }

        await this.roomManager.joinRoom(socket, roomId, RoomType.CALL);

        this.roomManager.broadcastToRoom(roomId, 'call:state_changed', {
          callId,
          state: 'active',
          metadata: { answeredBy: socket.user.userId },
        });

        Logger.info('Call answered', {
          callId,
          userId: socket.user.userId,
        });

        callback({
          success: true,
          callId,
        });
      } catch (error) {
        Logger.error('Call answer failed', {
          callId,
          userId: socket.user.userId,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
        callback({
          success: false,
          error: 'Failed to answer call',
        });
      }
    });
  }

  /**
   * Handle call rejection.
   */
  private setupRejectHandler(socket: AuthenticatedSocket): void {
    socket.on('call:reject', async (callId, reason) => {
      const roomId = this.roomManager.generateRoomId(RoomType.CALL, callId);

      this.roomManager.broadcastToRoom(roomId, 'call:ended', {
        callId,
        reason: 'rejected',
        duration: 0,
        timestamp: new Date(),
      });

      Logger.info('Call rejected', {
        callId,
        userId: socket.user.userId,
        reason,
      });
    });
  }

  /**
   * Handle hangup.
   */
  private setupHangupHandler(socket: AuthenticatedSocket): void {
    socket.on('call:hangup', async (callId) => {
      await this.roomManager.endCallRoom(callId);

      Logger.info('Call ended', {
        callId,
        userId: socket.user.userId,
      });
    });
  }

  /**
   * Handle mute/hold controls.
   */
  private setupCallControlHandlers(socket: AuthenticatedSocket): void {
    socket.on('call:mute', (callId, muted) => {
      const roomId = this.roomManager.generateRoomId(RoomType.CALL, callId);

      socket.to(roomId).emit('call:state_changed', {
        callId,
        state: 'active',
        metadata: {
          participantMuted: {
            userId: socket.user.userId,
            muted,
          },
        },
      });
    });

    socket.on('call:hold', (callId, held) => {
      const roomId = this.roomManager.generateRoomId(RoomType.CALL, callId);

      this.roomManager.broadcastToRoom(roomId, 'call:state_changed', {
        callId,
        state: held ? 'held' : 'active',
        metadata: {
          heldBy: socket.user.userId,
        },
      });
    });
  }

  /**
   * Emit incoming call to a user (to be used by HTTP routes/webhooks).
   */
  emitIncomingCall(
    userId: string,
    callId: string,
    fromNumber: string,
    toNumber: string,
    callerName?: string,
  ): void {
    this.roomManager.sendToUser(userId, 'call:incoming', {
      callId,
      fromNumber,
      toNumber,
      callerName,
      timestamp: new Date(),
    });
  }
}


