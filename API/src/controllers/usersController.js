import { pool } from '../config/db.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

export const creatUser = async (req, res) => {
    try {
        const {tipo_identificacion,identificacion,nombre,apellido,correo,telefono, usuario, contrasena,rol} = req.body; 
        const contrasena_hash = await bcrypt.hash(contrasena, 10);
        const sql = 'SELECT * FROM sp_user_create($1, $2, $3, $4, $5, $6, $7, $8, $9)';
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