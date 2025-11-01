import express from 'express';
import { creatUser } from '../controllers/usersController';

const router = express.Router();

router.post('/', creatUser);


export default router;