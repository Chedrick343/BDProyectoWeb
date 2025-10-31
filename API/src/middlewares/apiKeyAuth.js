// src/middlewares/apiKeyAuth.js
import dotenv from 'dotenv';
dotenv.config();

export const apiKeyAuth = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey) {
    return res.status(401).json({
      status: 'error',
      message: 'Falta la API Key en los headers (x-api-key).'
    });
  }

  if (apiKey !== process.env.API_KEY) {
    return res.status(403).json({
      status: 'error',
      message: 'API Key inválida o no autorizada.'
    });
  }

  next();
};
