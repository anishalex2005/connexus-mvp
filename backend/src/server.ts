import App from './app';
import Logger from './config/logger';
import fs from 'fs';
import path from 'path';

const logDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir);
}

try {
  const app = new App();
  app.listen();
} catch (error) {
  Logger.error(`Failed to start server: ${(error as Error).message}`);
  process.exit(1);
}

