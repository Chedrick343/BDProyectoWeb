import { pool } from '../config/db.js';

export const getDataIBAN = async (req, res) => {
  try {
    const { iban } = req.body;

    if (!iban) {
      return res.status(400).json({
        status: 'error',
        message: 'Debe proporcionar un IBAN en el cuerpo de la solicitud.'
      });
    }

    // Llamamos al procedimiento almacenado
    const sql = 'SELECT * FROM sp_bank_validate_account($1)';
    const values = [iban.trim()];
    const { rows } = await pool.query(sql, values);

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'No se encontró una cuenta con el IBAN especificado.'
      });
    }

    const titular = rows[0];

    return res.status(200).json({
      status: 'success',
      message: 'Datos del titular obtenidos correctamente.',
      data: {
        nombre: titular.nombre,
        apellido: titular.apellido
      }
    });

  } catch (error) {
    console.error('Error en getDataIBAN:', error);

    if (error.message.includes('no existe')) {
      return res.status(404).json({
        status: 'error',
        message: error.message
      });
    }

    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al obtener los datos del titular.'
    });
  }
};
