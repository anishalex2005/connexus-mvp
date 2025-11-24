import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import callRoutes from './call.routes';
import aiRoutes from './ai.routes';
import smsRoutes from './sms.routes';
import analyticsRoutes from './analytics.routes';

const router = Router();

router.get('/docs', (_req, res) => {
  res.json({
    message: 'API Documentation',
    endpoints: {
      auth: '/auth - Authentication endpoints',
      users: '/users - User management endpoints',
      calls: '/calls - Call management endpoints',
      ai: '/ai - AI agent configuration endpoints',
      sms: '/sms - SMS management endpoints',
      analytics: '/analytics - Analytics endpoints',
    },
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/calls', callRoutes);
router.use('/ai', aiRoutes);
router.use('/sms', smsRoutes);
router.use('/analytics', analyticsRoutes);

export default router;

