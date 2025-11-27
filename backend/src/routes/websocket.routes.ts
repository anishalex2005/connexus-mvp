import { Router, type Request, type Response } from 'express';
import { getSocketServer } from '../websocket';
import { authenticateToken as authMiddleware } from '../middleware/auth.middleware';
import Logger from '../config/logger';

const router = Router();

/**
 * GET /api/v1/ws/stats
 * Get WebSocket server statistics.
 */
router.get('/stats', authMiddleware, (_req: Request, res: Response) => {
  const socketServer = getSocketServer();

  if (!socketServer) {
    res.status(503).json({
      success: false,
      error: 'WebSocket server not available',
    });
    return;
  }

  res.json({
    success: true,
    data: socketServer.getStats(),
  });
});

/**
 * POST /api/v1/ws/broadcast
 * Broadcast a message to all connected users.
 */
router.post('/broadcast', authMiddleware, (req: Request, res: Response) => {
  try {
    const { event, data, excludeUsers } = req.body;
    const socketServer = getSocketServer();

    if (!socketServer) {
      res.status(503).json({
        success: false,
        error: 'WebSocket server not available',
      });
      return;
    }

    if (!event || data === undefined) {
      res.status(400).json({
        success: false,
        error: 'Event and data are required',
      });
      return;
    }

    socketServer.broadcast(event, data, excludeUsers);

    Logger.info('Broadcast message sent', {
      event,
      excludeCount: Array.isArray(excludeUsers) ? excludeUsers.length : 0,
    });

    res.json({
      success: true,
      message: 'Broadcast sent successfully',
    });
  } catch (error) {
    Logger.error('Broadcast failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    res.status(500).json({
      success: false,
      error: 'Failed to send broadcast',
    });
  }
});

/**
 * POST /api/v1/ws/send-to-user
 * Send a message to a specific user.
 */
router.post('/send-to-user', authMiddleware, (req: Request, res: Response) => {
  try {
    const { userId, event, data } = req.body;
    const socketServer = getSocketServer();

    if (!socketServer) {
      res.status(503).json({
        success: false,
        error: 'WebSocket server not available',
      });
      return;
    }

    if (!userId || !event || data === undefined) {
      res.status(400).json({
        success: false,
        error: 'userId, event, and data are required',
      });
      return;
    }

    socketServer.sendToUser(userId, event, data);

    Logger.info('Message sent to user', { userId, event });

    res.json({
      success: true,
      message: 'Message sent successfully',
    });
  } catch (error) {
    Logger.error('Send to user failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    res.status(500).json({
      success: false,
      error: 'Failed to send message',
    });
  }
});

/**
 * POST /api/v1/ws/disconnect-user
 * Force disconnect a user.
 */
router.post('/disconnect-user', authMiddleware, (req: Request, res: Response) => {
  try {
    const { userId, reason } = req.body;
    const socketServer = getSocketServer();

    if (!socketServer) {
      res.status(503).json({
        success: false,
        error: 'WebSocket server not available',
      });
      return;
    }

    if (!userId) {
      res.status(400).json({
        success: false,
        error: 'userId is required',
      });
      return;
    }

    socketServer.getConnectionManager().disconnectUser(userId, reason);

    Logger.info('User disconnected via API', { userId, reason });

    res.json({
      success: true,
      message: 'User disconnected successfully',
    });
  } catch (error) {
    Logger.error('Disconnect user failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    res.status(500).json({
      success: false,
      error: 'Failed to disconnect user',
    });
  }
});

/**
 * GET /api/v1/ws/user/:userId/status
 * Check if a user is online.
 */
router.get('/user/:userId/status', authMiddleware, (req: Request, res: Response) => {
  const { userId } = req.params;
  const socketServer = getSocketServer();

  if (!socketServer) {
    res.status(503).json({
      success: false,
      error: 'WebSocket server not available',
    });
    return;
  }

  const isOnline = socketServer.getConnectionManager().isUserOnline(userId);
  const socketCount = socketServer.getConnectionManager().getUserSocketIds(userId).length;

  res.json({
    success: true,
    data: {
      userId,
      isOnline,
      connectionCount: socketCount,
    },
  });
});

export default router;


