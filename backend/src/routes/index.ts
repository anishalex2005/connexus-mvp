import { Router, Request, Response } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import callRoutes from './call.routes';
import aiRoutes from './ai.routes';
import smsRoutes from './sms.routes';
import analyticsRoutes from './analytics.routes';
import websocketRoutes from './websocket.routes';
import telephonyRoutes from './telephony.routes';
import webrtcRoutes from './webrtc.routes';
import { userRepository, callRecordRepository } from '../repositories';

const router = Router();

// API Info endpoint
router.get('/', (_req: Request, res: Response) => {
  res.json({
    name: 'ConnexUS API',
    version: '1.0.0',
    endpoints: {
      auth: '/auth',
      users: '/users',
      calls: '/calls',
      sms: '/sms',
      ai: '/ai',
      analytics: '/analytics',
      telephony: '/telephony',
      webrtc: '/webrtc',
    },
  });
});

// API Documentation endpoint
router.get('/docs', (_req: Request, res: Response) => {
  res.json({
    message: 'API Documentation',
    endpoints: {
      auth: '/auth - Authentication endpoints',
      users: '/users - User management endpoints',
      calls: '/calls - Call management endpoints',
      ai: '/ai - AI agent configuration endpoints',
      sms: '/sms - SMS management endpoints',
      analytics: '/analytics - Analytics endpoints',
      telephony: '/telephony - Telephony/SIP credential endpoints',
      webrtc: '/webrtc - WebRTC ICE/TURN configuration endpoints',
    },
  });
});

// Test database connectivity and repositories (development only)
if (process.env.NODE_ENV !== 'production') {
  router.get('/test-db', async (_req: Request, res: Response) => {
    try {
      const userCount = await userRepository.count();
      const testUser = await userRepository.findByEmail('test@connexus.dev');

      let callStats: unknown = null;
      if (testUser) {
        callStats = await callRecordRepository.getStats(testUser.id);
      }

      res.json({
        success: true,
        message: 'Database connection and repositories working correctly',
        data: {
          userCount,
          testUserExists: !!testUser,
          testUserEmail: testUser?.email,
          callStats,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });
}

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/calls', callRoutes);
router.use('/ai', aiRoutes);
router.use('/sms', smsRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/ws', websocketRoutes);
router.use('/telephony', telephonyRoutes);
router.use('/webrtc', webrtcRoutes);

export default router;

