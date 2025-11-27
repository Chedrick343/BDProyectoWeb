import { pool } from '../config/db.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

export const creatUser = async (req, res) => {
    try {
        const {tipo_identificacion,identificacion,nombre,apellido,correo,telefono, usuario, contrasena,rol} = req.body; 
        const contrasena_hash = await bcrypt.hash(contrasena, 10);
        const sql = 'SELECT * FROM sp_users_create($1, $2, $3, $4, $5, $6, $7, $8, $9)';
        const values = [tipo_identificacion,identificacion,nombre,apellido,correo,telefono, usuario, contrasena_hash,rol];

        const { rows } = await pool.query(sql, values);
        const userId = rows[0].user_id;

        return  res.status(201).json({
            status: 'success',
            message: 'Usuario creado correctamente.',
            data: {
                userId
            }
        });

    }catch (error) {
        console.error('Error en creatUser:', error);
        return res.status(500).json({
          status: 'error',
          message: 'Ocurrió un error al crear el usuario.'
    });
  }
};

export const getUserByIdentification = async (req, res) => {
  const { identification } = req.params;
  const authUser = req.user;
  console.log(identification, authUser);

  try {
    const result = await pool.query(
      "SELECT * FROM sp_users_get_by_identification($1);",
      [identification]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }

    const user = result.rows[0];

    const isAdmin = authUser.rol === "admin" || authUser.rol === "Admin";
    const isOwner = identification === user.identificacion;

    if (!isAdmin && !isOwner) {
      return res.status(403).json({ message: "Acceso denegado" });
    }
    console.log(user);
    res.status(200).json({
      id: user.id,
      nombre: user.nombre,
      apellido: user.apellido,
      correo: user.correo,
      usuario: user.usuario,
      rol: user.nombre_rol
    });
  } catch (error) {
    console.error("Error al consultar usuario:", error);
    res.status(500).json({ message: "Error interno del servidor" });
  }
};

export const deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const sql = 'SELECT * FROM sp_users_delete($1)';
    await pool.query(sql, [userId]);

    return res.status(200).json({
      status: 'success',
      message: 'Usuario eliminado correctamente.'
    });

  } catch (error) {
    console.error('Error en deleteUser:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al eliminar el usuario.'
    });
  }
};

export const updateUser = async (req, res) => {
  try {
    const { userId } = req.params; // ID del usuario a modificar
    const { nombre, apellido, correo, usuario, rol, telefono } = req.body;

    // Verificar que al menos un campo venga con datos
    if (!nombre && !apellido && !correo && !usuario && !rol && !telefono) {
      return res.status(400).json({
        status: 'error',
        message: 'No se proporcionaron campos para actualizar.'
      });
    }

    // Llamar al procedimiento almacenado (solo Admin puede acceder aquí)
    const sql = `
      SELECT sp_users_update($1, $2, $3, $4, $5, $6, $7) AS updated;
    `;
    const values = [
      userId,
      nombre,
      apellido,
      correo,
      usuario,
      rol,
      telefono
    ];

    const { rows } = await pool.query(sql, values);
    const updated = rows[0]?.updated;

    if (!updated) {
      return res.status(404).json({
        status: 'error',
        message: 'Usuario no encontrado o no se realizaron cambios.'
      });
    }

    return res.status(200).json({
      status: 'success',
      message: 'Usuario actualizado correctamente.'
    });

  } catch (error) {
    console.error('Error en updateUser:', error);

    if (error.message.includes('Correo') || error.message.includes('usuario')) {
      return res.status(400).json({
        status: 'error',
        message: error.message
      });
    }

    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al actualizar el usuario.'
    });
  }
};

export const getUserId = async (req, res) => {
  try {
    const { id } = req.body; 

    if (!id) {
      return res.status(400).json({
        status: "error",
        message: "Debe proporcionar un ID de usuario en el body."
      });
    }

    const query = `
      SELECT identificacion 
      FROM usuario 
      WHERE id = $1;
    `;

    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        status: "error",
        message: "Usuario no encontrado."
      });
    }

    return res.status(200).json({
      status: "success",
      identificacion: result.rows[0].identificacion
    });

  } catch (error) {
    console.error("Error en getUserId:", error);

    return res.status(500).json({
      status: "error",
      message: "Error interno del servidor."
    });
  }
};
