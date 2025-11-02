import express from 'express';
import { createAccount, getAccounts, getDetails } from '../controllers/accountsController.js';
import { verifyToken } from '../middlewares/verifyToken.js';
import { checkRole } from '../middlewares/checkRole.js';

const router = express.Router();

router.post('/', verifyToken, createAccount);
router.get('/', verifyToken, checkRole(['Admin', 'Cliente']), getAccounts);
router.get('/cuenta/:accountId', verifyToken, checkRole(['Admin', 'Cliente']), getAccounts);
router.get('/details/:accountId', verifyToken, checkRole(['Admin', 'Cliente']), getDetails);

export default router;
