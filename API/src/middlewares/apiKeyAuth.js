// src/middlewares/apiKeyAuth.js
import dotenv from 'dotenv';
import { pool } from "../config/db.js";
dotenv.config();

export const apiKeyAuth =  async (req, res, next) => {
  try {
    const apiKey = req.headers['x-api-key'];

    if (!apiKey) {
      return res.status(401).json({
        status: 'error',
        message: 'Falta la API Key en los headers (x-api-key).'
      });
    }
    const query = "SELECT sp_api_key_is_active($1) AS is_active";
    const { rows } = await pool.query(query, [apiKey]);

    const isActive = rows.length > 0 ? rows[0].is_active : false;

    if (!isActive) {
      return res.status(403).json({
        status: "error",
        message: "API Key inválida o inactiva.",
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
