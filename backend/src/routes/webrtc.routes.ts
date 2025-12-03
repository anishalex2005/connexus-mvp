import { Router, Request, Response } from 'express';
import crypto from 'crypto';

import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Telnyx TURN server configuration
const TURN_SERVER = process.env.TURN_SERVER_URL || 'turn:turn.telnyx.com:3478';
const TURN_SECRET = process.env.TURN_SECRET || '';
const TURN_TTL = 86400; // 24 hours in seconds

/**
 * Generate time-limited TURN credentials
 * Uses HMAC-based credentials for security
 */
function generateTurnCredentials(userId: string): {
  username: string;
  credential: string;
  ttl: number;
} {
  const timestamp = Math.floor(Date.now() / 1000) + TURN_TTL;
  const username = `${timestamp}:${userId}`;

  const hmac = crypto.createHmac('sha1', TURN_SECRET);
  hmac.update(username);
  const credential = hmac.digest('base64');

  return {
    username,
    credential,
    ttl: TURN_TTL,
  };
}

/**
 * GET /api/v1/webrtc/turn-credentials
 * Returns time-limited TURN server credentials for WebRTC
 */
router.get(
  '/turn-credentials',
  authenticateToken,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).authUser?.userId || 'anonymous';

      const credentials = generateTurnCredentials(userId);

      res.json({
        url: TURN_SERVER,
        urls: [
          TURN_SERVER,
          `${TURN_SERVER}?transport=tcp`,
          `${TURN_SERVER}?transport=udp`,
        ],
        username: credentials.username,
        credential: credentials.credential,
        ttl: credentials.ttl,
        expiresAt: new Date(
          Date.now() + credentials.ttl * 1000,
        ).toISOString(),
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error generating TURN credentials:', error);
      res.status(500).json({ error: 'Failed to generate TURN credentials' });
    }
  },
);

/**
 * GET /api/v1/webrtc/ice-servers
 * Returns complete ICE server configuration
 */
router.get(
  '/ice-servers',
  authenticateToken,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).authUser?.userId || 'anonymous';
      const turnCredentials = generateTurnCredentials(userId);

      res.json({
        iceServers: [
          // STUN servers
          { urls: 'stun:stun.l.google.com:19302' },
          { urls: 'stun:stun1.l.google.com:19302' },
          { urls: 'stun:stun.telnyx.com:3478' },
          // TURN servers with credentials
          {
            urls: [TURN_SERVER, `${TURN_SERVER}?transport=tcp`],
            username: turnCredentials.username,
            credential: turnCredentials.credential,
          },
        ],
        ttl: turnCredentials.ttl,
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error getting ICE servers:', error);
      res.status(500).json({ error: 'Failed to get ICE servers' });
    }
  },
);

export default router;


