import { Router } from 'express';
import authController from '../controllers/auth.controller';
import { authenticateToken, rateLimitAuth } from '../middleware/auth.middleware';

const router = Router();

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', rateLimitAuth, (req, res) => {
  void authController.register(req, res);
});

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user and get tokens
 * @access  Public
 */
router.post('/login', rateLimitAuth, (req, res) => {
  void authController.login(req, res);
});

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refresh access token
 * @access  Public (requires valid refresh token in body)
 */
router.post('/refresh', (req, res) => {
  void authController.refreshToken(req, res);
});

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Logout user
 * @access  Private
 */
router.post('/logout', authenticateToken, (req, res) => {
  void authController.logout(req, res);
});

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', authenticateToken, (req, res) => {
  void authController.getCurrentUser(req, res);
});

export default router;

