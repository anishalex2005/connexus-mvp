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
    this.app.get('/health', (_req: Request, res: Response) => {
      res.status(200).json({
        status: 'success',
        message: 'ConnexUS API is running',
        timestamp: new Date().toISOString(),
        environment: config.env,
        version: config.apiVersion,
      });
    });

    this.app.use(`${config.apiPrefix}/${config.apiVersion}`, routes);

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
    const server = this.app.listen(port, () => {
      Logger.info(`🚀 Server is running on port ${port}`);
      Logger.info(
        `📚 API Documentation: http://localhost:${port}${config.apiPrefix}/${config.apiVersion}/docs`
      );
      Logger.info(`🏥 Health Check: http://localhost:${port}/health`);
      Logger.info(`🌍 Environment: ${config.env}`);
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

