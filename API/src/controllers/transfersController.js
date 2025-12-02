import { pool } from '../config/db.js';

export const createInternalTransfer = async (req, res) => {
    let client;
    
    try {
        const { from_account_id, to_account_id, amount, currency, description } = req.body;
        const user_id = req.user.id;

        // Validaciones básicas
        if (!from_account_id || !to_account_id || !amount || !currency) {
            return res.status(400).json({
                success: false,
                message: 'Faltan campos obligatorios',
                http_code: 400,
                error_code: 'MISSING_FIELDS'
            });
        }

        if (amount <= 0) {
            return res.status(400).json({
                success: false,
                message: 'El monto debe ser mayor a cero',
                http_code: 400,
                error_code: 'INVALID_AMOUNT'
            });
        }

        client = await pool.connect();
        
        try {
            await client.query('BEGIN');

            const sql = `SELECT * FROM sp_transfer_create_internal($1, $2, $3, $4, $5, $6)`;
            const values = [from_account_id, to_account_id, amount, currency, description || '', user_id];

            const result = await client.query(sql, values);
            const transferResult = result.rows[0];

            if (!transferResult) {
                await client.query('ROLLBACK');
                return res.status(500).json({
                    success: false,
                    message: 'Error procesando transferencia',
                    http_code: 500,
                    error_code: 'INTERNAL_ERROR'
                });
            }

            if (transferResult.status !== 'success') {
                await client.query('ROLLBACK');
                
                // Mapear todos los posibles errores
                const errorMapping = {
                    'unauthorized': {
                        code: 403,
                        message: 'No autorizado para realizar esta transferencia',
                        error_code: 'FORBIDDEN'
                    },
                    'account_not_found': {
                        code: 404,
                        message: 'Cuenta no encontrada',
                        error_code: 'ACCOUNT_NOT_FOUND'
                    },
                    'account_inactive': {
                        code: 400,
                        message: 'La cuenta no está activa',
                        error_code: 'ACCOUNT_INACTIVE'
                    },
                    'insufficient_funds': {
                        code: 400,
                        message: 'Fondos insuficientes',
                        error_code: 'INSUFFICIENT_FUNDS'
                    },
                    'currency_mismatch': {
                        code: 400,
                        message: 'Las cuentas deben tener la misma moneda',
                        error_code: 'CURRENCY_MISMATCH'
                    },
                    'same_account': {
                        code: 400,
                        message: 'No se puede transferir a la misma cuenta',
                        error_code: 'SAME_ACCOUNT'
                    },
                    'invalid_currency': {
                        code: 400,
                        message: 'Moneda no válida',
                        error_code: 'INVALID_CURRENCY'
                    },
                    'invalid_amount': {
                        code: 400,
                        message: 'Monto no válido',
                        error_code: 'INVALID_AMOUNT'
                    },
                    'error': {
                        code: 500,
                        message: 'Error interno del servidor',
                        error_code: 'INTERNAL_ERROR'
                    }
                };

                const errorInfo = errorMapping[transferResult.status] || {
                    code: 400,
                    message: 'Error en la transferencia',
                    error_code: 'TRANSFER_ERROR'
                };

                return res.status(errorInfo.code).json({
                    success: false,
                    message: errorInfo.message,
                    http_code: errorInfo.code,
                    error_code: errorInfo.error_code
                });
            }

            await client.query('COMMIT');

            return res.status(201).json({
                success: true,
                message: 'Transferencia realizada exitosamente',
                http_code: 201,
                data: {
                    transfer_id: transferResult.transfer_id,
                    receipt_number: transferResult.receipt_number,
                    status: 'completed'
                }
            });

        } catch (sqlError) {
            if (client) {
                await client.query('ROLLBACK');
            }
            throw sqlError;
        }

    } catch (error) {
        console.error('[Transferencia] Error:', error);
        
        return res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            http_code: 500,
            error_code: 'INTERNAL_ERROR'
        });

    } finally {
        if (client) {
            client.release();
        }
    }
};