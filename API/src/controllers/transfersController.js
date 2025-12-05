import { pool } from '../config/db.js';

export const createInternalTransfer = async (req, res) => {
    let client;
    
    try {
        const { from_account_iban, to_account_iban, amount, currency_code, description } = req.body;

        // Validaciones básicas
        if (!from_account_iban || !to_account_iban || !amount || !currency_code) {
            return res.status(400).json({
                success: false,
                message: 'Faltan campos obligatorios: from_account_iban, to_account_iban, amount, currency_code',
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

            const sql = `SELECT * FROM sp_transfer_create_internal($1, $2, $3, $4, $5)`;
            const values = [from_account_iban, to_account_iban, amount, currency_code, description || ''];

            const result = await client.query(sql, values);
            const transferResult = result.rows[0];

            if (!transferResult) {
                await client.query('ROLLBACK');
                return res.status(500).json({
                    success: false,
                    message: 'Error procesando transferencia: respuesta inválida',
                    http_code: 500,
                    error_code: 'INTERNAL_ERROR'
                });
            }

            // Si hay error del stored procedure
            if (transferResult.status === 'error') {
                await client.query('ROLLBACK');
                
                // Mapeo de códigos de error del SP a respuestas HTTP
                const errorMapping = {
                    'INVALID_FROM_IBAN': {
                        code: 400,
                        message: 'El IBAN de origen es requerido',
                        error_code: 'INVALID_IBAN'
                    },
                    'INVALID_TO_IBAN': {
                        code: 400,
                        message: 'El IBAN de destino es requerido',
                        error_code: 'INVALID_IBAN'
                    },
                    'FROM_ACCOUNT_NOT_FOUND': {
                        code: 404,
                        message: 'La cuenta de origen no existe',
                        error_code: 'ACCOUNT_NOT_FOUND'
                    },
                    'TO_ACCOUNT_NOT_FOUND': {
                        code: 404,
                        message: 'La cuenta de destino no existe',
                        error_code: 'ACCOUNT_NOT_FOUND'
                    },
                    'INVALID_CURRENCY': {
                        code: 400,
                        message: 'La moneda especificada no es válida',
                        error_code: 'INVALID_CURRENCY'
                    },
                    'FROM_ACCOUNT_INACTIVE': {
                        code: 400,
                        message: 'La cuenta de origen no está activa',
                        error_code: 'ACCOUNT_INACTIVE'
                    },
                    'TO_ACCOUNT_INACTIVE': {
                        code: 400,
                        message: 'La cuenta de destino no está activa',
                        error_code: 'ACCOUNT_INACTIVE'
                    },
                    'SAME_ACCOUNT': {
                        code: 400,
                        message: 'No puedes transferir a la misma cuenta',
                        error_code: 'SAME_ACCOUNT'
                    },
                    'INSUFFICIENT_FUNDS': {
                        code: 400,
                        message: 'Fondos insuficientes en la cuenta de origen',
                        error_code: 'INSUFFICIENT_FUNDS'
                    },
                    'FROM_CURRENCY_MISMATCH': {
                        code: 400,
                        message: 'La moneda de la cuenta origen no coincide',
                        error_code: 'CURRENCY_MISMATCH'
                    },
                    'TO_CURRENCY_MISMATCH': {
                        code: 400,
                        message: 'La moneda de la cuenta destino no coincide',
                        error_code: 'CURRENCY_MISMATCH'
                    },
                    'INVALID_AMOUNT': {
                        code: 400,
                        message: 'El monto debe ser mayor a cero',
                        error_code: 'INVALID_AMOUNT'
                    },
                    'INTERNAL_ERROR': {
                        code: 500,
                        message: transferResult.error_message || 'Error interno del servidor',
                        error_code: 'INTERNAL_ERROR'
                    }
                };

                const errorInfo = errorMapping[transferResult.error_code] || {
                    code: 400,
                    message: transferResult.error_message || 'Error en la transferencia',
                    error_code: transferResult.error_code || 'TRANSFER_ERROR'
                };

                return res.status(errorInfo.code).json({
                    success: false,
                    message: errorInfo.message,
                    http_code: errorInfo.code,
                    error_code: errorInfo.error_code,
                    details: transferResult.error_message
                });
            }

            // Transferencia exitosa
            await client.query('COMMIT');

            return res.status(201).json({
                success: true,
                message: 'Transferencia realizada exitosamente',
                http_code: 201,
                data: {
                    transfer_id: transferResult.transfer_id,
                    receipt_number: transferResult.receipt_number,
                    status: transferResult.status,
                    description: description || ''
                }
            });

        } catch (sqlError) {
            if (client) {
                await client.query('ROLLBACK');
            }
            
            // Error de base de datos
            console.error('[Transferencia] Error SQL:', sqlError);
            
            return res.status(500).json({
                success: false,
                message: 'Error en la base de datos',
                http_code: 500,
                error_code: 'DATABASE_ERROR',
                details: sqlError.message
            });

        } finally {
            if (client) {
                client.release();
            }
        }

    } catch (error) {
        console.error('[Transferencia] Error general:', error);
        
        return res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            http_code: 500,
            error_code: 'INTERNAL_ERROR'
        });
    }
};

// Función de validación opcional para los parámetros
const validateTransferInput = (input) => {
    const errors = [];
    
    // Validar formato de IBAN (ejemplo básico)
    const ibanRegex = /^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$/;
    
    if (!input.from_account_iban || typeof input.from_account_iban !== 'string') {
        errors.push('IBAN de origen inválido');
    } else if (!ibanRegex.test(input.from_account_iban.replace(/\s/g, ''))) {
        errors.push('Formato de IBAN de origen inválido');
    }
    
    if (!input.to_account_iban || typeof input.to_account_iban !== 'string') {
        errors.push('IBAN de destino inválido');
    } else if (!ibanRegex.test(input.to_account_iban.replace(/\s/g, ''))) {
        errors.push('Formato de IBAN de destino inválido');
    }
    
    if (!input.amount || isNaN(parseFloat(input.amount)) || parseFloat(input.amount) <= 0) {
        errors.push('Monto inválido');
    }
    
    if (!input.currency_code || typeof input.currency_code !== 'string' || input.currency_code.length !== 3) {
        errors.push('Código de moneda inválido (debe ser 3 caracteres)');
    }
    
    return errors;
};