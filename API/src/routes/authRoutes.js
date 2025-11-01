import express from 'express';
import { apiKeyAuth } from '../middlewares/apiKeyAuth.js';
import { login, forgotPassword, verifyOtp, resetPassword} from '../controllers/authController.js';

const router = express.Router();

router.post('/login', apiKeyAuth, login);
router.post('/forgot-password', apiKeyAuth, forgotPassword);
router.post('/verify-otp', apiKeyAuth, verifyOtp);
router.post('/reset-password', apiKeyAuth, resetPassword);
export default router;
