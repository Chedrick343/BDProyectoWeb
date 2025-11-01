import { pool } from '../config/db.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';

export const login = async (req, res) => {
  try{
    const { username_or_email, email, username, password } = req.body;
    const identifier = (username_or_email || email || username || '').toString().trim();
    if (!identifier || !password) {
      return res.status(400).json({ message: 'Faltan credenciales', status: 'error' });
    }
    const sql = 'SELECT * FROM sp_auth_user_get_by_username_or_email($1)';
    const { rows } = await pool.query(sql, [identifier]);


    if (!rows || rows.length === 0) {
      return res.status(401).json({ status: 'error', message: 'Credenciales inválidas.' });
    }
    const user = rows[0];
    const passwordHash = user.contrasena_hash;

    const match = await bcrypt.compare(password, passwordHash);
    if (!match) {
      return res.status(401).json({ status: 'error', message: 'Credenciales inválidas.' });
    }

    const payload = {
      userId: user.user_id,
      role: user.rol_nombre
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
    return res.status(200).json({
      status: 'success',
      message: 'Autenticación correcta.',
      data: {
        token,
        expiresIn: JWT_EXPIRES_IN
      }
    });

  }catch (error) {
    console.error('Error en login:', err);
    // No devuelvas el error de BD al cliente
    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al procesar la autenticación.'
    });
  }
};