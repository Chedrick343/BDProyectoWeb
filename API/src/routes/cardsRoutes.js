import express from 'express';
import { createCard, getCards, getCardById, getCardMovements, addCardMovement, generateOtpTemporalVisualization, consumeOtpTemporalVisualization } from '../controllers/cardsController.js';
import { verifyToken } from '../middlewares/verifyToken.js';

const router = express.Router();

router.post('/',verifyToken, createCard); 
router.get('/',verifyToken, getCards); 
router.get('/:cardId',verifyToken, getCardById);
router.get('/:cardId/movements',verifyToken, getCardMovements); 
router.post('/:cardId/movements',verifyToken, addCardMovement);
router.post('/:cardId/otp',verifyToken, generateOtpTemporalVisualization);
router.post('/:cardId/view-details',verifyToken, consumeOtpTemporalVisualization);

export default router;