import { Router, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';

import db from '../database';
import { authenticateToken } from '../middleware/auth.middleware';
import type { AuthenticatedRequest } from '../types/auth.types';

const router = Router();

// All routes require authentication.
router.use(authenticateToken);

/**
 * GET /api/v1/telephony/credentials
 * Retrieves SIP credentials for the authenticated user.
 */
router.get(
  '/credentials',
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const userId = req.authUser?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated',
        });
        return;
      }

      const result = await db('user_telephony_credentials')
        .select(
          'sip_username',
          'sip_password',
          'caller_id_name',
          'caller_id_number',
          'fcm_token',
          'is_active',
          'created_at',
          'updated_at'
        )
        .where({ user_id: userId, is_active: true })
        .first();

      if (!result) {
        res.status(404).json({
          success: false,
          message: 'No telephony credentials found for user',
        });
        return;
      }

      res.json({
        success: true,
        data: {
          sip_username: result.sip_username,
          sip_password: result.sip_password,
          caller_id_name: result.caller_id_name,
          caller_id_number: result.caller_id_number,
          fcm_token: result.fcm_token,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/telephony/credentials
 * Creates or updates SIP credentials for the authenticated user.
 */
router.post(
  '/credentials',
  [
    body('sip_username').notEmpty().isString().trim(),
    body('sip_password').notEmpty().isString(),
    body('caller_id_name').optional().isString().trim(),
    body('caller_id_number').optional().isString().trim(),
  ],
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({
          success: false,
          errors: errors.array(),
        });
        return;
      }

      const userId = req.authUser?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated',
        });
        return;
      }

      const {
        sip_username,
        sip_password,
        caller_id_name,
        caller_id_number,
      } = req.body as {
        sip_username: string;
        sip_password: string;
        caller_id_name?: string;
        caller_id_number?: string;
      };

      const [row] = await db('user_telephony_credentials')
        .insert({
          user_id: userId,
          sip_username,
          sip_password,
          caller_id_name,
          caller_id_number,
          is_active: true,
        })
        .onConflict('user_id')
        .merge({
          sip_username,
          sip_password,
          caller_id_name,
          caller_id_number,
          is_active: true,
          updated_at: db.fn.now(),
        })
        .returning(['sip_username', 'caller_id_name', 'caller_id_number']);

      res.status(201).json({
        success: true,
        message: 'Credentials saved successfully',
        data: {
          sip_username: row.sip_username,
          caller_id_name: row.caller_id_name,
          caller_id_number: row.caller_id_number,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * PUT /api/v1/telephony/fcm-token
 * Updates the FCM token for push notifications.
 */
router.put(
  '/fcm-token',
  [body('fcm_token').notEmpty().isString()],
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({
          success: false,
          errors: errors.array(),
        });
        return;
      }

      const userId = req.authUser?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated',
        });
        return;
      }

      const { fcm_token } = req.body as { fcm_token: string };

      await db('user_telephony_credentials')
        .update({
          fcm_token,
          updated_at: db.fn.now(),
        })
        .where({ user_id: userId });

      res.json({
        success: true,
        message: 'FCM token updated successfully',
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * DELETE /api/v1/telephony/credentials
 * Deactivates credentials (soft delete).
 */
router.delete(
  '/credentials',
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const userId = req.authUser?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated',
        });
        return;
      }

      await db('user_telephony_credentials')
        .update({
          is_active: false,
          updated_at: db.fn.now(),
        })
        .where({ user_id: userId });

      res.json({
        success: true,
        message: 'Credentials deactivated successfully',
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /api/v1/telephony/connection-status
 * Returns the expected connection status (for app startup).
 */
router.get(
  '/connection-status',
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const userId = req.authUser?.userId;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated',
        });
        return;
      }

      const result = await db('user_telephony_credentials')
        .select('is_active', 'last_connected_at', 'connection_count')
        .where({ user_id: userId })
        .first();

      if (!result) {
        res.json({
          success: true,
          data: {
            has_credentials: false,
            is_active: false,
          },
        });
        return;
      }

      res.json({
        success: true,
        data: {
          has_credentials: true,
          is_active: result.is_active,
          last_connected_at: result.last_connected_at,
          connection_count: result.connection_count,
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;


