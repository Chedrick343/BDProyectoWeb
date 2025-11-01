import bcrypt from "bcrypt";
import { pool } from "../db/config.js"; // Ajustá a tu conexión real

export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "El email es requerido" });

    const result = await pool.query(
        "SELECT * FROM sp_users_get_by_email($1)",
        [email]
    );

    if (userQuery.rowCount === 0)
      return res.status(404).json({ message: "Usuario no encontrado" });

    const userId = result.rows[0].user_id;

    const otp = Math.floor(100000 + Math.random() * 900000).toString();


    const otpHash = await bcrypt.hash(otp, 10);

    await pool.query("SELECT sp_otp_create($1, 'password_reset', 300, $2)", [userId, otpHash]);


    res.json({
      message: "Código OTP generado correctamente. Enviando por email (simulado).",
      otp,
    });

  } catch (err) {
    console.error("Error en forgotPassword:", err);
    res.status(500).json({ message: "Error interno del servidor" });
  }
};