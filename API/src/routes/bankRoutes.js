import express from 'express';
import { verifyToken } from '../middlewares/verifyToken.js';
import { getDataIBAN } from '../controllers/bankController.js';

const router = express.Router();

router.post('/validate-account', verifyToken, getDataIBAN);

export default router;
