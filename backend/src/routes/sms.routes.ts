import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

router.get(
  '/templates',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'SMS templates endpoint - To be implemented in Task 50',
    });
  })
);

router.post(
  '/send',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Send SMS endpoint - To be implemented in Task 53',
    });
  })
);

export default router;

