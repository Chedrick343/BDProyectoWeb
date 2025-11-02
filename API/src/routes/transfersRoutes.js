import express from 'express';
import { createInternalTransfer } from '../controllers/transfersController.js';
import { verifyToken } from '../middlewares/verifyToken.js';

const router = express.Router();

router.post('/internal', verifyToken , createInternalTransfer);

export default router;