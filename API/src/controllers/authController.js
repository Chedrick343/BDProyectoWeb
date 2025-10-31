// src/controllers/authController.js
export const login = async (req, res) => {
  const { email, password } = req.body;
  console.log(`Intento de login para el email: ${email}`);
  console.log(`Password recibido: ${password}`);

  // Aquí luego ejecutarás el SP de autenticación
  if (email === 'test@banco.com' && password === '1234') {
    return res.status(200).json({
      message: 'Login exitoso (simulado)',
      token: 'jwt_simulado_123'
    });
  }

  res.status(401).json({ message: 'Credenciales inválidas' });
};

export const forgotPassword = async (req, res) => {
  res.status(200).json({ message: 'Solicitud de recuperación enviada (mock)' });
};

export const resetPassword = async (req, res) => {
  res.status(200).json({ message: 'Contraseña restablecida (mock)' });
};
