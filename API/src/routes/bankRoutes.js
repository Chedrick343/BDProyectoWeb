import express from 'express';
import { apiKeyAuthToken } from '../middlewares/verifiTokenBank.js';
import { getDataIBAN } from '../controllers/bankController.js';

const router = express.Router();

router.post('/validate-account', apiKeyAuthToken, getDataIBAN);

export default router;
