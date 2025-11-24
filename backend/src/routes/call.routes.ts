import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware';

const router = Router();

router.post(
  '/initiate',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Call initiation endpoint - To be implemented in Tasks 19-25',
    });
  })
);

router.post(
  '/webhook',
  asyncHandler(async (req: Request, res: Response) => {
    // Telnyx webhook placeholder
    // eslint-disable-next-line no-console
    console.log('Telnyx webhook received:', req.body);
    res.status(200).json({
      status: 'success',
      message: 'Webhook received',
    });
  })
);

router.get(
  '/history',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Call history endpoint - To be implemented in Task 75',
    });
  })
);

router.post(
  '/transfer',
  asyncHandler(async (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'success',
      message: 'Call transfer endpoint - To be implemented in Task 48',
    });
  })
);

export default router;

