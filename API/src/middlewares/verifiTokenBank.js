// src/middlewares/apiKeyAuth.js
import dotenv from 'dotenv';
import { pool } from "../config/db.js";
dotenv.config();

export const apiKeyAuthToken =  async (req, res, next) => {
  try {
    const apiKey = req.headers['x-api-token'];
    console.log ("API Token recibida:", apiKey);

    if (!apiKey) {
      return res.status(401).json({
        status: 'error',
        message: 'Falta la API token en los headers (X-API-TOKEN).'
      });
    }
    const isValid = apiKey === process.env.JWT_FOR_BANK;

    if (!isValid) {
      return res.status(403).json({
        status: "error",
        message: "API Token inválida o inactiva.",
      });
    }
    next()
  }catch (error) {
    console.error("Error en verifyApiKey:", error);
    res.status(500).json({
      status: "error",
      message: "Error interno al validar la API Key.",
    });
  }
};
