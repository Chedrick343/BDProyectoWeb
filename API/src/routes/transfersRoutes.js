import express from 'express';
import { createInternalTransfer, interbankTransfer } from '../controllers/transfersController.js';
import { verifyToken } from '../middlewares/verifyToken.js';

const router = express.Router();

router.post('/internal', verifyToken , createInternalTransfer);
router.post('/interbank', verifyToken , interbankTransfer);

export default router;