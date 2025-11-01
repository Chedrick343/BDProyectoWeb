import express from 'express';
import { creatUser, getUserByIdentification } from '../controllers/usersController.js';
import { verifyToken } from '../middlewares/verifyToken.js';
const router = express.Router();

router.post('/', creatUser);
router.get('/:identification', verifyToken, getUserByIdentification);


export default router;