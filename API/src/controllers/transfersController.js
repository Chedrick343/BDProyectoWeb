import { pool } from '../config/db.js';

export const createInternalTransfer = async (req, res) => {
    try {

        if (!req.body) {
            return res.status(400).json({
                status: 'error',
                message: 'Cuerpo de la solicitud vacío o inválido'
            });
        }

        const { from_account_id, to_account_id, amount, currency, description } = req.body;
        const user_id = req.user.userId; // Obtenido del JWT

        // Validaciones básicas
        if (!from_account_id || !to_account_id || !amount || !currency) {
            return res.status(400).json({
                status: 'error',
                message: 'Faltan campos obligatorios: from_account_id, to_account_id, amount, currency'
            });
        }

        if (amount <= 0) {
            return res.status(400).json({
                status: 'error',
                message: 'El monto debe ser mayor a cero'
            });
        }

        // Llamar al stored procedure
        const sql = 'SELECT * FROM sp_transfer_create_internal($1, $2, $3, $4, $5, $6)';
        const values = [from_account_id, to_account_id, amount, currency, description, user_id];

        const { rows } = await pool.query(sql, values);
        const result = rows[0];

        // Manejar diferentes estados de la transferencia
        if (result.status === 'insufficient_funds') {
            return res.status(400).json({
                status: 'error',
                message: 'Fondos insuficientes para realizar la transferencia'
            });
        }

        if (result.status === 'currency_mismatch') {
            return res.status(400).json({
                status: 'error',
                message: 'Las cuentas no tienen la misma moneda'
            });
        }

        if (result.status === 'error') {
            return res.status(500).json({
                status: 'error',
                message: 'Error interno al procesar la transferencia'
            });
        }

        // Éxito
        return res.status(201).json({
            status: 'success',
            message: 'Transferencia realizada correctamente',
            data: {
                transfer_id: result.transfer_id,
                receipt_number: result.receipt_number,
                status: result.status
            }
        });

    } catch (error) {
        console.error('Error en createInternalTransfer:', error);
        
        // Manejar errores específicos de la base de datos
        if (error.message.includes('violates foreign key constraint')) {
            return res.status(400).json({
                status: 'error',
                message: 'Una de las cuentas especificadas no existe'
            });
        }

        return res.status(500).json({
            status: 'error',
            message: 'Ocurrió un error al procesar la transferencia'
        });
    }
};
