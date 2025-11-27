import express from 'express';
import { creatUser, getUserByIdentification, deleteUser, updateUser, getUserId } from '../controllers/usersController.js';
import { verifyToken } from '../middlewares/verifyToken.js';
import {checkRole} from '../middlewares/checkRole.js';
const router = express.Router();

router.post('/', creatUser);
router.get('/:identification', verifyToken, getUserByIdentification);
router.delete('/:userId', verifyToken, checkRole(['Admin']), deleteUser);
router.put('/:userId', verifyToken,checkRole(['Admin']), updateUser);
router.get('/id', verifyToken, getUserId)

export default router;
