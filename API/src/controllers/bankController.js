import { pool } from '../config/db.js';

export const getDataIBAN = async (req, res) => {
  try {
    const { iban } = req.body;
    const esCuentaValida = evaluarIban(iban);
    

    if (!esCuentaValida) {
      return res.status(400).json({
        error: 'INVALID_ACCOUNT_FORMAT',
        message: 'El formato iban no es válido.'
      });
    }

    const sql = 'SELECT * FROM sp_bank_validate_account($1)';
    const values = [iban.trim()];
    const { rows } = await pool.query(sql, values);

    if (!rows || rows.length === 0) {
      return res.status(200).json({
        exists: false,
        info: null
      });
    }

    const titular = rows[0];

    return res.status(200).json({
      exists: true,
      info: {
        name: titular.nombre + ' ' + titular.apellido,
        identification: titular.identificacion,
        currency: titulartular.currency,
        debit: true,
        credit: true
      }
    });

  } catch (error) {
    console.error('Error en getDataIBAN:', error);

    if (error.message.includes('no existe')) {
      return res.status(200).json({
        exists: false,
        info: null
      });
    }

    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al obtener los datos del titular.'
    });
  }
};

function evaluarIban(iban) {

  const ibanRegex = /^CR01B08\d{12}$/;
  return ibanRegex.test(iban);
}