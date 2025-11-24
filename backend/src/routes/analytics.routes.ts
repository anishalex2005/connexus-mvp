import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

router.get(
  '/dashboard',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Analytics dashboard - To be implemented in Task 79',
    });
  })
);

router.get(
  '/export',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Analytics export - To be implemented in Task 80',
    });
  })
);

export default router;

