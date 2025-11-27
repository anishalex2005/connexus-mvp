import fs from 'fs';
import path from 'path';
import App from './app';
import Logger from './config/logger';
import { checkDatabaseConnection, closeDatabaseConnection } from './database';

const logDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir);
}

async function startServer(): Promise<void> {
  try {
    const dbConnected = await checkDatabaseConnection();

    if (!dbConnected) {
      Logger.error('Failed to connect to database. Exiting...');
      process.exit(1);
    }

    const app = new App();
    app.listen();
  } catch (error) {
    Logger.error(`Failed to start server: ${(error as Error).message}`);
    process.exit(1);
  }
}

process.on('SIGTERM', () => {
  Logger.info('SIGTERM received. Shutting down gracefully...');
  void closeDatabaseConnection().finally(() => {
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  Logger.info('SIGINT received. Shutting down gracefully...');
  void closeDatabaseConnection().finally(() => {
    process.exit(0);
  });
});

void startServer();

