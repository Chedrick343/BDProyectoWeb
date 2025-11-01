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
        expiresIn: JWT_EXPIRES_IN,
        id: user.user_id
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



export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "El email es requerido" });

    const result = await pool.query(
        "SELECT * FROM sp_users_get_by_email($1)",
        [email]
    );

    if (result.rowCount === 0)
      return res.status(404).json({ message: "Codigo otp generado, si tu correo es correcto llegará a tu email" });

    const userId = result.rows[0].id;

    const otp = Math.floor(100000 + Math.random() * 900000).toString();


    const otpHash = await bcrypt.hash(otp, 10);

    await pool.query("SELECT sp_otp_create($1, 'password_reset', 300, $2)", [userId, otpHash]);


    res.json({
      message: "Codigo otp generado, si tu correo es correcto llegará a tu email (Verdadero).",
      otp,
      id: userId
    });

  } catch (err) {
    console.error("Error en forgotPassword:", err);
    res.status(500).json({ message: "Error interno del servidor" });
  }
};

export const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ message: "Email y OTP son requeridos" });
    }

    const userResult = await pool.query(
        "SELECT * FROM sp_users_get_by_email($1)",
        [email]
    );
    
    if (userResult.rowCount === 0)
      return res.status(404).json({ message: "Usuario no encontrado" });
    const userId = userResult.rows[0].id;

    const otpResult = await pool.query(
        "SELECT * FROM sp_otp_get($1, 'password_reset')",
        [userId]
    );

    if (otpResult.rowCount === 0) {
      return res.status(400).json({ message: "OTP inválido o expirado" });
    }

    const otpRecord = otpResult.rows[0];

    const isMatch = await bcrypt.compare(otp, otpRecord.codigo_hash);
    if (!isMatch) {
      return res.status(400).json({ message: "OTP inválido" });
    }

    res.json({ message: "OTP verificado correctamente",
      id: userId,
      codigo: otpRecord.codigo_hash
     });

  } catch (err) {
    console.error("Error en verifyOtp:", err);
    res.status(500).json({ message: "Error interno del servidor" });
  }
};

export const resetPassword = async (req, res) => {
  try {
    const { userId, otpHash, newPassword } = req.body;
    if (!userId || !otpHash || !newPassword) {
      return res.status(400).json({ message: "Faltan datos requeridos" });
    }

    const newPasswordHash = await bcrypt.hash(newPassword, 10);

    const result = await pool.query(
        "SELECT sp_otp_consume($1, 'password_reset', $2, $3) AS success",
        [userId, otpHash, newPasswordHash]
    );

    const success = result.rows[0].success;

    if (!success) {
      return res.status(400).json({ message: "No se pudo actualizar la contraseña. OTP inválido o ya consumido." });
    }

    res.json({ message: "Contraseña actualizada correctamente" });

  } catch (err) {
    console.error("Error en resetPassword:", err);
    res.status(500).json({ message: "Error interno del servidor" });
  }
};