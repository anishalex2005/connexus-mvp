import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import config from './config';
import Logger from './config/logger';
import { errorHandler, notFoundHandler } from './middleware/error.middleware';
import routes from './routes';
import db, { checkDatabaseConnection, getPoolStats } from './database';
import { getSocketServer, initializeSocketServer } from './websocket';
import type { Server } from 'http';

class App {
  public app: Application;

  constructor() {
    this.app = express();
    this.initializeMiddleware();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  private initializeMiddleware(): void {
    this.app.use(
      helmet({
        contentSecurityPolicy: config.env === 'production',
        crossOriginEmbedderPolicy: config.env === 'production',
      })
    );

    this.app.use(
      cors({
        origin: config.cors.origin,
        credentials: config.cors.credentials,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
      })
    );

    const limiter = rateLimit({
      windowMs: config.rateLimit.windowMs,
      max: config.rateLimit.max,
      message: 'Too many requests from this IP, please try again later.',
      standardHeaders: true,
      legacyHeaders: false,
    });
    this.app.use(`${config.apiPrefix}/`, limiter);

    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    this.app.use(compression());

    const morganMiddleware = morgan(
      ':remote-addr :method :url :status :res[content-length] - :response-time ms',
      {
        stream: {
          write: (message: string) => (Logger as any).http(message.trim()),
        },
      }
    );
    this.app.use(morganMiddleware);

    this.app.use((req: Request, res: Response, next: NextFunction) => {
      req.id = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      res.setHeader('X-Request-Id', req.id as string);
      next();
    });
  }

  private initializeRoutes(): void {
    this.app.get('/health', async (_req: Request, res: Response) => {
      const dbConnected = await checkDatabaseConnection();
      const poolStats = getPoolStats();
      const socketServer = getSocketServer();
      const wsStats = socketServer?.getStats();

      res.status(200).json({
        status: 'success',
        message: 'ConnexUS API is running',
        timestamp: new Date().toISOString(),
        environment: config.env,
        version: config.apiVersion,
        database: {
          connected: dbConnected,
          pool: poolStats,
        },
        websocket: wsStats
          ? {
              connections: wsStats.connections.totalConnections,
              users: wsStats.connections.uniqueUsers,
              rooms: wsStats.rooms.totalRooms,
            }
          : null,
      });
    });

    if (config.env !== 'production') {
      this.app.get('/db-stats', async (_req: Request, res: Response) => {
        try {
          const poolStats = getPoolStats();

          const tableCounts = await Promise.all([
            db('users').count('* as count').first(),
            db('phone_numbers').count('* as count').first(),
            db('call_records').count('* as count').first(),
            db('sms_templates').count('* as count').first(),
            db('ai_configurations').count('* as count').first(),
          ]);

          const toInt = (value: unknown): number => {
            if (typeof value === 'number') return value;
            if (typeof value === 'string') return parseInt(value, 10) || 0;
            return 0;
          };

          res.json({
            pool: poolStats,
            tables: {
              users: toInt(tableCounts[0]?.count),
              phone_numbers: toInt(tableCounts[1]?.count),
              call_records: toInt(tableCounts[2]?.count),
              sms_templates: toInt(tableCounts[3]?.count),
              ai_configurations: toInt(tableCounts[4]?.count),
            },
          });
        } catch (error) {
          Logger.error('Failed to get database stats', error as Error);
          res.status(500).json({ error: 'Failed to get database stats' });
        }
      });
    }

    this.app.use(`${config.apiPrefix}/${config.apiVersion}`, routes);

    this.app.get('/ws/stats', (_req: Request, res: Response) => {
      const socketServer = getSocketServer();

      if (!socketServer) {
        res.status(503).json({ error: 'WebSocket server not initialized' });
        return;
      }

      res.json(socketServer.getStats());
    });

    this.app.get('/', (_req: Request, res: Response) => {
      res.status(200).json({
        message: 'Welcome to ConnexUS API',
        version: config.apiVersion,
        documentation: `${config.apiPrefix}/${config.apiVersion}/docs`,
      });
    });
  }

  private initializeErrorHandling(): void {
    this.app.use(notFoundHandler);
    this.app.use(errorHandler);

    process.on('unhandledRejection', (err: Error) => {
      Logger.error(`UNHANDLED REJECTION! 💥 Shutting down...`);
      Logger.error(`${err.name} ${err.message}`);
      process.exit(1);
    });

    process.on('uncaughtException', (err: Error) => {
      Logger.error(`UNCAUGHT EXCEPTION! 💥 Shutting down...`);
      Logger.error(`${err.name} ${err.message}`);
      process.exit(1);
    });
  }

  public listen(): void {
    const port = config.port;
    const server: Server = this.app.listen(port, () => {
      Logger.info(`🚀 Server is running on port ${port}`);
      Logger.info(
        `📚 API Documentation: http://localhost:${port}${config.apiPrefix}/${config.apiVersion}/docs`,
      );
      Logger.info(`🏥 Health Check: http://localhost:${port}/health`);
      Logger.info(`🌍 Environment: ${config.env}`);

      const socketServer = initializeSocketServer(server);
      void socketServer
        .initialize()
        .then(() => {
          Logger.info(`🔌 WebSocket server ready on port ${port}`);
        })
        .catch((error: unknown) => {
          Logger.error('Failed to initialize WebSocket server', error as Error);
        });
    });

    process.on('SIGTERM', () => {
      Logger.info('SIGTERM received. Performing graceful shutdown...');
      server.close(() => {
        Logger.info('Process terminated');
        process.exit(0);
      });
    });
  }
}

export default App;

