import type { Server as HttpServer } from 'http';
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import type {
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData,
  AuthenticatedSocket,
} from './types/socket.types';
import { socketAuthMiddleware } from './middleware/socket-auth.middleware';
import { ConnectionManager } from './services/connection-manager.service';
import { RoomManager } from './services/room-manager.service';
import { ConnectionHandler } from './handlers/connection.handler';
import { CallHandler } from './handlers/call.handler';
import Logger from '../config/logger';

export class SocketServer {
  private io: Server<ClientToServerEvents, ServerToClientEvents, InterServerEvents, SocketData>;
  private connectionManager: ConnectionManager;
  private roomManager: RoomManager;
  private connectionHandler: ConnectionHandler;
  private callHandler: CallHandler;
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor(httpServer: HttpServer) {
    this.io = new Server<ClientToServerEvents, ServerToClientEvents, InterServerEvents, SocketData>(
      httpServer,
      {
        cors: {
          origin: process.env.WS_CORS_ORIGIN?.split(',') || '*',
          methods: ['GET', 'POST'],
          credentials: true,
        },
        pingInterval: parseInt(process.env.WS_PING_INTERVAL || '25000', 10),
        pingTimeout: parseInt(process.env.WS_PING_TIMEOUT || '20000', 10),
        transports: ['websocket', 'polling'],
        allowUpgrades: true,
        path: '/socket.io/',
      },
    );

    this.connectionManager = new ConnectionManager(this.io);
    this.roomManager = new RoomManager(this.io);

    this.connectionHandler = new ConnectionHandler(this.connectionManager, this.roomManager);
    this.callHandler = new CallHandler(this.roomManager);
  }

  /**
   * Initialize the WebSocket server.
   */
  async initialize(): Promise<void> {
    if (process.env.REDIS_URL) {
      await this.setupRedisAdapter();
    }

    this.io.use(socketAuthMiddleware.authenticate);

    this.io.on('connection', (socket) => {
      const authenticatedSocket = socket as AuthenticatedSocket;

      Logger.info('New socket connection', {
        socketId: socket.id,
        userId: authenticatedSocket.user?.userId,
        ip: socket.handshake.address,
      });

      this.connectionHandler.setupHandlers(authenticatedSocket);
      this.callHandler.setupHandlers(authenticatedSocket);
    });

    this.startCleanupInterval();

    Logger.info('WebSocket server initialized', {
      corsOrigins: process.env.WS_CORS_ORIGIN,
      pingInterval: process.env.WS_PING_INTERVAL,
      pingTimeout: process.env.WS_PING_TIMEOUT,
      redisEnabled: !!process.env.REDIS_URL,
    });
  }

  /**
   * Set up Redis adapter for horizontal scaling.
   */
  private async setupRedisAdapter(): Promise<void> {
    try {
      const pubClient = createClient({ url: process.env.REDIS_URL });
      const subClient = pubClient.duplicate();

      await Promise.all([pubClient.connect(), subClient.connect()]);

      this.io.adapter(createAdapter(pubClient, subClient));

      Logger.info('Redis adapter configured for WebSocket');
    } catch (error) {
      Logger.error('Failed to configure Redis adapter', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * Start periodic cleanup of stale connections.
   */
  private startCleanupInterval(): void {
    this.cleanupInterval = setInterval(() => {
      this.connectionManager.cleanupStaleConnections();
    }, 5 * 60 * 1000);
  }

  /**
   * Get connection statistics.
   */
  getStats(): {
    connections: ReturnType<ConnectionManager['getStats']>;
    rooms: ReturnType<RoomManager['getStats']>;
  } {
    return {
      connections: this.connectionManager.getStats(),
      rooms: this.roomManager.getStats(),
    };
  }

  /**
   * Get the Socket.IO server instance.
   */
  getIO(): Server<ClientToServerEvents, ServerToClientEvents, InterServerEvents, SocketData> {
    return this.io;
  }

  /**
   * Get the connection manager.
   */
  getConnectionManager(): ConnectionManager {
    return this.connectionManager;
  }

  /**
   * Get the room manager.
   */
  getRoomManager(): RoomManager {
    return this.roomManager;
  }

  /**
   * Get the call handler.
   */
  getCallHandler(): CallHandler {
    return this.callHandler;
  }

  /**
   * Broadcast to all connected clients.
   */
  broadcast<T>(event: string, data: T, excludeUsers?: string[]): void {
    if (excludeUsers && excludeUsers.length > 0) {
      const excludeSockets: string[] = [];
      for (const userId of excludeUsers) {
        excludeSockets.push(...this.connectionManager.getUserSocketIds(userId));
      }
      this.io.except(excludeSockets).emit(event as any, data);
    } else {
      this.io.emit(event as any, data);
    }
  }

  /**
   * Send to specific user.
   */
  sendToUser<T>(userId: string, event: string, data: T): void {
    this.roomManager.sendToUser(userId, event, data);
  }

  /**
   * Graceful shutdown.
   */
  async shutdown(): Promise<void> {
    Logger.info('Shutting down WebSocket server...');

    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }

    this.io.emit('system:maintenance', {
      type: 'emergency',
      message: 'Server is shutting down',
    });

    await new Promise<void>((resolve) => {
      this.io.close(() => {
        Logger.info('WebSocket server shut down');
        resolve();
      });
    });
  }
}

let socketServer: SocketServer | null = null;

/**
 * Initialize and get the socket server instance.
 */
export function initializeSocketServer(httpServer: HttpServer): SocketServer {
  if (!socketServer) {
    socketServer = new SocketServer(httpServer);
  }
  return socketServer;
}

/**
 * Get the existing socket server instance.
 */
export function getSocketServer(): SocketServer | null {
  return socketServer;
}


