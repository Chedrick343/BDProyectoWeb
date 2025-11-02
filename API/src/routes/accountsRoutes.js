import express from 'express';
import { createAccount, getAccounts, getAccountDetails, getMovements, setAccountState } from '../controllers/accountsController.js';
import { verifyToken } from '../middlewares/verifyToken.js';
import { checkRole } from '../middlewares/checkRole.js';

const router = express.Router();

router.post('/', verifyToken, createAccount);
router.get('/', verifyToken, checkRole(['Admin', 'Cliente']), getAccounts);
router.get('/:accountId', verifyToken, checkRole(['Admin', 'Cliente']), getAccountDetails);
router.get('/:accountId/movements', verifyToken, checkRole(['Admin', 'Cliente']), getMovements);
router.post('/:accountId/status', verifyToken, setAccountState);
export default router;
