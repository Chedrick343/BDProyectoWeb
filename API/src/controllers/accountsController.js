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

export const getMovements = async (req, res) => {
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

export const setAccountState = async (req, res) => {
  try {
    const { accountId } = req.params;
    const { nuevoEstado } = req.body;
    const { userId, role } = req.user; // Datos del JWT

    if (!accountId || !nuevoEstado) {
      return res.status(400).json({
        status: 'error',
        message: 'Debe especificar el ID de la cuenta y el nuevo estado.'
      });
    }

    // 1️⃣ Verificar que la cuenta pertenece al usuario autenticado
    const checkSql = 'SELECT usuario_id FROM cuenta WHERE id = $1';
    const { rows: cuentaRows } = await pool.query(checkSql, [accountId]);

    if (cuentaRows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Cuenta no encontrada.'
      });
    }

    const ownerId = cuentaRows[0].usuario_id;

    // Solo el dueño o un admin puede cambiarla (si quieres permitir admin también, deja el OR)
    if (ownerId !== userId /* && role !== 'Admin' */) {
      return res.status(403).json({
        status: 'error',
        message: 'No tienes permiso para cambiar el estado de esta cuenta.'
      });
    }

    // 2️⃣ Ejecutar el procedimiento almacenado
    const sql = 'SELECT sp_accounts_set_status($1, $2) AS updated';
    const values = [accountId, nuevoEstado];
    const { rows } = await pool.query(sql, values);
    const updated = rows[0]?.updated;

    if (!updated) {
      return res.status(400).json({
        status: 'error',
        message: 'No se realizó ningún cambio en el estado de la cuenta.'
      });
    }

    return res.status(200).json({
      status: 'success',
      message: `El estado de la cuenta se cambió correctamente a "${nuevoEstado}".`
    });

  } catch (error) {
    console.error('Error en setAccountState:', error);

    if (error.message.includes('cerrar') || error.message.includes('saldo')) {
      return res.status(400).json({
        status: 'error',
        message: error.message
      });
    }

    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al cambiar el estado de la cuenta.'
    });
  }
};

export const getAccountDetails = async (req, res) => {
  try {
    const { accountId } = req.params;
    const { userId } = req.user; // viene del token JWT

    if (!accountId) {
      return res.status(400).json({
        status: 'error',
        message: 'Debe proporcionar el ID de la cuenta.'
      });
    }

    const sql = 'SELECT * FROM sp_get_account_details($1, $2)';
    const values = [userId, accountId];
    const { rows } = await pool.query(sql, values);

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Cuenta no encontrada o sin permisos para acceder.'
      });
    }

    return res.status(200).json({
      status: 'success',
      message: 'Detalles de la cuenta obtenidos correctamente.',
      data: rows[0]
    });

  } catch (error) {
    console.error('Error en getAccountDetails:', error);

    return res.status(500).json({
      status: 'error',
      message: 'Ocurrió un error al obtener los detalles de la cuenta.'
    });
  }
};
