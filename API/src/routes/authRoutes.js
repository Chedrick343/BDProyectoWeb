import express from 'express';
import { apiKeyAuth } from '../middlewares/apiKeyAuth.js';
import { login } from '../controllers/authController.js';

const router = express.Router();

router.post('/login', apiKeyAuth, login);

export default router;
