import knex, { Knex } from 'knex';
import config from '../config';

const knexConfig: Knex.Config = {
  client: 'pg',
  connection: {
    host: config.database.host,
    port: config.database.port,
    database: config.database.name,
    user: config.database.user,
    password: config.database.password,
  },
  pool: {
    min: config.database.poolMin,
    max: config.database.poolMax,
    acquireTimeoutMillis: 30000,
    createTimeoutMillis: 30000,
    destroyTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
    reapIntervalMillis: 1000,
    createRetryIntervalMillis: 100,
  },
  migrations: {
    tableName: 'knex_migrations',
  },
};

// Create the database connection instance
const db: Knex = knex(knexConfig);

// Connection pool event handlers for monitoring
db.on('query', (query) => {
  if (process.env.DB_DEBUG === 'true') {
    // eslint-disable-next-line no-console
    console.log('SQL Query:', query.sql);
    if (query.bindings?.length) {
      // eslint-disable-next-line no-console
      console.log('Bindings:', query.bindings);
    }
  }
});

// Health check function
export async function checkDatabaseConnection(): Promise<boolean> {
  try {
    await db.raw('SELECT 1');
    // eslint-disable-next-line no-console
    console.log('✅ Database connection established successfully');
    return true;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('❌ Database connection failed:', error);
    return false;
  }
}

// Graceful shutdown function
export async function closeDatabaseConnection(): Promise<void> {
  try {
    await db.destroy();
    // eslint-disable-next-line no-console
    console.log('Database connection pool closed');
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error closing database connection:', error);
  }
}

// Get pool statistics
export function getPoolStats(): { used: number; free: number; pending: number } {
  const pool: any = (db.client as any).pool;
  return {
    used: typeof pool.numUsed === 'function' ? pool.numUsed() : 0,
    free: typeof pool.numFree === 'function' ? pool.numFree() : 0,
    pending: typeof pool.numPendingAcquires === 'function' ? pool.numPendingAcquires() : 0,
  };
}

export default db;


