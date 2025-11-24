import { Router, Request, Response } from 'express';
import { body } from 'express-validator';
import { validateRequest } from '../middleware/validation.middleware';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

router.post(
  '/register',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }).trim(),
    body('firstName').notEmpty().trim(),
    body('lastName').notEmpty().trim(),
    validateRequest,
  ],
  asyncHandler(async (req: Request, res: Response) => {
    res.status(201).json({
      status: 'success',
      message: 'Registration endpoint - To be implemented in Task 11',
      data: req.body,
    });
  })
);

router.post(
  '/login',
  [body('email').isEmail().normalizeEmail(), body('password').notEmpty(), validateRequest],
  asyncHandler(async (req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Login endpoint - To be implemented in Task 11',
      data: req.body,
    });
  })
);

router.post(
  '/logout',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Logout endpoint - To be implemented in Task 11',
    });
  })
);

router.post(
  '/refresh',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Token refresh endpoint - To be implemented in Task 11',
    });
  })
);

router.post(
  '/forgot-password',
  [body('email').isEmail().normalizeEmail(), validateRequest],
  asyncHandler(async (req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Password reset endpoint - To be implemented in Task 29',
      data: req.body,
    });
  })
);

export default router;

