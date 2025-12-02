import { pool } from '../config/db.js';

/**
 * @desc    Crear una transferencia interna entre cuentas
 * @route   POST /api/v1/transfers/internal
 * @access  Private (JWT requerido)
 */
export const createInternalTransfer = async (req, res) => {
    let client;
    
    try {
        // ========== VALIDACIONES INICIALES ==========
        if (!req.body || Object.keys(req.body).length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Cuerpo de la solicitud vacío o inválido',
                http_code: 400,
                error_code: 'EMPTY_BODY'
            });
        }

        const { 
            from_account_id, 
            to_account_id, 
            amount, 
            currency, 
            description
        } = req.body;

        const user_id = req.user.id;

        // Validar campos obligatorios
        const requiredFields = ['from_account_id', 'to_account_id', 'amount', 'currency'];
        const missingFields = requiredFields.filter(field => !req.body[field]);
        
        if (missingFields.length > 0) {
            return res.status(400).json({
                success: false,
                message: `Faltan campos obligatorios: ${missingFields.join(', ')}`,
                http_code: 400,
                error_code: 'MISSING_FIELDS'
            });
        }

        // Validar tipos de datos
        if (typeof amount !== 'number' || isNaN(amount)) {
            return res.status(400).json({
                success: false,
                message: 'El monto debe ser un número válido',
                http_code: 400,
                error_code: 'INVALID_AMOUNT_TYPE'
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

        // Validar formato de UUIDs
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        
        if (!uuidRegex.test(from_account_id) || 
            !uuidRegex.test(to_account_id) || 
            !uuidRegex.test(currency)) {
            return res.status(400).json({
                success: false,
                message: 'Formato inválido para alguno de los IDs',
                http_code: 400,
                error_code: 'INVALID_UUID_FORMAT'
            });
        }

        // ========== EJECUTAR TRANSFERENCIA ==========
        client = await pool.connect();
        
        try {
            await client.query('BEGIN');

            // Ejecutar función de transferencia
            const sql = `
                SELECT * FROM sp_transfer_create_internal(
                    $1, $2, $3, $4, $5, $6
                )
            `;
            
            const values = [
                from_account_id, 
                to_account_id, 
                amount, 
                currency, 
                description || '', 
                user_id
            ];

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

            // ========== MANEJAR RESULTADO ==========
            if (transferResult.status !== 'success') {
                await client.query('ROLLBACK');
                
                // Mapear códigos de error
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

                // Agregar datos adicionales para errores específicos
                const errorResponse = {
                    success: false,
                    message: errorInfo.message,
                    http_code: errorInfo.code,
                    error_code: errorInfo.error_code
                };

                if (errorInfo.error_code === 'INSUFFICIENT_FUNDS') {
                    try {
                        const balanceCheck = await client.query(
                            'SELECT saldo FROM cuenta WHERE id = $1',
                            [from_account_id]
                        );
                        if (balanceCheck.rows[0]) {
                            errorResponse.data = {
                                current_balance: balanceCheck.rows[0].saldo,
                                required_amount: amount,
                                deficit: amount - balanceCheck.rows[0].saldo
                            };
                        }
                    } catch (e) {
                        // Continuar sin datos adicionales
                    }
                }

                return res.status(errorInfo.code).json(errorResponse);
            }

            // ========== TRANSFERENCIA EXITOSA ==========
            await client.query('COMMIT');

            // Obtener información adicional
            let accountInfo = {};
            try {
                const infoResult = await client.query(`
                    SELECT 
                        c1.iban as from_iban,
                        c1.alias as from_alias,
                        c1.saldo as from_new_balance,
                        c2.iban as to_iban,
                        c2.alias as to_alias,
                        m.iso as currency_iso,
                        u2.nombre as to_owner_name
                    FROM cuenta c1
                    JOIN cuenta c2 ON c2.id = $2
                    JOIN moneda m ON m.id = $3
                    JOIN usuario u2 ON c2.usuario_id = u2.id
                    WHERE c1.id = $1
                `, [from_account_id, to_account_id, currency]);

                if (infoResult.rows[0]) {
                    accountInfo = infoResult.rows[0];
                }
            } catch (infoError) {
                // Continuar sin información adicional
            }

            // Construir respuesta de éxito
            return res.status(201).json({
                success: true,
                message: 'Transferencia realizada exitosamente',
                http_code: 201,
                data: {
                    transfer: {
                        id: transferResult.transfer_id,
                        receipt_number: transferResult.receipt_number,
                        status: 'completed',
                        timestamp: new Date().toISOString()
                    },
                    from_account: {
                        id: from_account_id,
                        iban: accountInfo.from_iban,
                        alias: accountInfo.from_alias,
                        new_balance: accountInfo.from_new_balance
                    },
                    to_account: {
                        id: to_account_id,
                        iban: accountInfo.to_iban,
                        alias: accountInfo.to_alias,
                        owner_name: accountInfo.to_owner_name
                    },
                    transaction: {
                        amount: amount,
                        currency: accountInfo.currency_iso,
                        description: description || 'Transferencia interna'
                    }
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
        
        // Manejo de errores
        let statusCode = 500;
        let errorMessage = 'Error interno del servidor';
        let errorCode = 'INTERNAL_ERROR';

        if (error.message.includes('violates foreign key constraint')) {
            statusCode = 400;
            errorMessage = 'Datos inválidos en la solicitud';
            errorCode = 'BAD_REQUEST';
        } else if (error.message.includes('connection')) {
            statusCode = 503;
            errorMessage = 'Servicio no disponible';
            errorCode = 'SERVICE_UNAVAILABLE';
        }

        return res.status(statusCode).json({
            success: false,
            message: errorMessage,
            http_code: statusCode,
            error_code: errorCode
        });

    } finally {
        if (client) {
            client.release();
        }
    }
};