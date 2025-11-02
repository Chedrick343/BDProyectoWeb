import { pool } from '../config/db.js';

export const createAccount = async (req, res) => {
  try {
    const { userId, role } = req.user; // obtenido del token JWT
    const { iban, alias, tipo_cuenta, moneda, saldo_inicial, estado } = req.body;

    // Solo los clientes pueden crear sus propias cuentas
    if (role !== 'Cliente') {
      return res.status(403).json({
        status: 'error',
        message: 'Solo los clientes pueden crear cuentas.'
      });
    }

    // Llamar al procedimiento almacenado
    const sql = `
      SELECT sp_accounts_create($1, $2, $3, $4, $5, $6, $7) AS account_id;`;
    const values = [
      userId,
      iban,
      alias || null,
      tipo_cuenta,
      moneda,
      saldo_inicial,
      estado
    ];

    const { rows } = await pool.query(sql, values);
    const accountId = rows[0]?.account_id;

    if (!accountId) {
      return res.status(500).json({
        status: 'error',
        message: 'No se pudo crear la cuenta.'
      });
    }

    return res.status(201).json({
      status: 'success',
      message: 'Cuenta creada correctamente.',
      data: {
        account_id: accountId
      }
    });

  } catch (error) {
    console.error('Error en createAccount:', error);

    if (error.message.includes('no existe') || error.message.includes('ya existe')) {
      return res.status(400).json({
        status: 'error',
        message: error.message
      });
    }

    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al crear la cuenta.'
    });
  }
};
export const getAccounts = async (req, res) => {
  try {
    const { userId, role } = req.user;
    const { ownerId } = req.query;         // ahora viene por query param
    const { accountId } = req.params;      // opcional

    // Determinar propietario real
    const targetOwnerId = role === 'Admin' && ownerId ? ownerId : userId;

    if (role === 'Cliente' && ownerId && ownerId !== userId) {
      return res.status(403).json({
        status: 'error',
        message: 'No tienes permiso para ver las cuentas de otro usuario.'
      });
    }

    const sql = `SELECT * FROM sp_accounts_get($1, $2);`;
    const { rows } = await pool.query(sql, [targetOwnerId, accountId || null]);

    if (!rows.length) {
      return res.status(404).json({
        status: 'error',
        message: 'No se encontraron cuentas.'
      });
    }

    return res.status(200).json({
      status: 'success',
      message: 'Cuentas obtenidas correctamente.',
      data: rows
    });
  } catch (error) {
    console.error('Error en getAccounts:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Error al obtener las cuentas.'
    });
  }
};

export const getDetails = async (req, res) => {
  try {
    const { accountId } = req.params;
    const { userId, role } = req.user; // viene del token JWT

    if (!accountId) {
      return res.status(400).json({
        status: 'error',
        message: 'Debe proporcionar el ID de la cuenta.'
      });
    }

    // Validar que la cuenta exista y obtener su dueño
    const checkSql = 'SELECT usuario_id FROM cuenta WHERE id = $1';
    const checkResult = await pool.query(checkSql, [accountId]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Cuenta no encontrada.'
      });
    }

    const ownerId = checkResult.rows[0].usuario_id;

    // Solo el dueño o un admin pueden ver los movimientos
    if (role !== 'Admin' && ownerId !== userId) {
      return res.status(403).json({
        status: 'error',
        message: 'No tienes permiso para ver los movimientos de esta cuenta.'
      });
    }

    // Ejecutar el procedimiento almacenado
    const sql = 'SELECT * FROM sp_accounts_get_details($1)';
    const { rows } = await pool.query(sql, [accountId]);

    return res.status(200).json({
      status: 'success',
      message: 'Movimientos obtenidos correctamente.',
      data: rows
    });

  } catch (error) {
    console.error('Error en getDetails:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al obtener los detalles de la cuenta.'
    });
  }
};

