import { pool } from '../config/db.js';
import bcrypt from 'bcrypt';

export const createCard = async (req, res) => {
    try {
        const { 
            tipo, 
            numero_enmascarado, 
            fecha_expiracion, 
            cvv, 
            pin, 
            moneda, 
            limite_credito 
        } = req.body;
        
        const usuario_id = req.user.userId;

        // Validaciones básicas
        if (!tipo || !numero_enmascarado || !fecha_expiracion || !cvv || !pin || !moneda || !limite_credito) {
            return res.status(400).json({
                status: 'error',
                message: 'Faltan campos obligatorios'
            });
        }

        // Encriptar CVV y PIN
        const cvv_encriptado = await bcrypt.hash(cvv, 10);
        const pin_encriptado = await bcrypt.hash(pin, 10);

        // Llamar al stored procedure
        const sql = 'SELECT * FROM sp_cards_create($1, $2, $3, $4, $5, $6, $7, $8, $9)';
        const values = [
            usuario_id,
            tipo,
            numero_enmascarado,
            fecha_expiracion,
            cvv_encriptado,
            pin_encriptado,
            moneda,
            limite_credito,
            0.00 // saldo_actual inicial
        ];

        const { rows } = await pool.query(sql, values);
        const cardId = rows[0].card_id;

        return res.status(201).json({
            status: 'success',
            message: 'Tarjeta creada correctamente',
            data: {
                card_id: cardId
            }
        });

    } catch (error) {
        console.error('Error en createCard:', error);
        return res.status(500).json({
            status: 'error',
            message: 'Ocurrió un error al crear la tarjeta'
        });
    }
};

export const getCards = async (req, res) => {
    try {
        const user_id = req.user.userId;
        const isAdmin = req.user.rol === 'admin' || req.user.rol === 'Admin';
        
        let owner_id = user_id;
        
        // Si es admin y se proporciona un owner_id específico, usarlo
        if (isAdmin && req.query.owner_id) {
            owner_id = req.query.owner_id;
        }

        // Llamar al stored procedure
        const sql = 'SELECT * FROM sp_cards_get($1, $2)';
        const values = [owner_id, null]; // owner_id, card_id (null para todas las tarjetas)

        const { rows } = await pool.query(sql, values);
        const result = rows[0];

        return res.status(200).json({
            status: 'success',
            message: 'Tarjetas obtenidas correctamente',
            data: {
                cards: result.cards || []
            }
        });

    } catch (error) {
        console.error('Error en getCards:', error);
        return res.status(500).json({
            status: 'error',
            message: 'Ocurrió un error al obtener las tarjetas'
        });
    }
};

export const getCardById = async (req, res) => {
    try {
        const { cardId } = req.params;
        const user_id = req.user.userId;
        const isAdmin = req.user.rol === 'admin' || req.user.rol === 'Admin';

        // Llamar al stored procedure para obtener la tarjeta específica
        const sql = 'SELECT * FROM sp_cards_get($1, $2)';
        const values = [null, cardId]; // owner_id null, card_id específico

        const { rows } = await pool.query(sql, values);
        const result = rows[0];

        if (!result.cards || result.cards.length === 0) {
            return res.status(404).json({
                status: 'error',
                message: 'Tarjeta no encontrada'
            });
        }

        const card = result.cards[0];

        // Verificar permisos (solo admin o dueño pueden ver la tarjeta)
        if (!isAdmin && card.usuario_id !== user_id) {
            return res.status(403).json({
                status: 'error',
                message: 'No tienes permisos para ver esta tarjeta'
            });
        }

        // Remover datos sensibles antes de enviar la respuesta
        const safeCard = { ...card };
        delete safeCard.cvv_hash;
        delete safeCard.pin_hash;

        return res.status(200).json({
            status: 'success',
            message: 'Tarjeta obtenida correctamente',
            data: safeCard
        });

    } catch (error) {
        console.error('Error en getCardById:', error);
        return res.status(500).json({
            status: 'error',
            message: 'Ocurrió un error al obtener la tarjeta'
        });
    }
};

export const getCardMovements = async (req, res) => {
    try {
        const { cardId } = req.params;
        const user_id = req.user.userId;
        const isAdmin = req.user.rol === 'admin' || req.user.rol === 'Admin';
        
        const { 
            page = 1, 
            page_size = 10, 
            from_date, 
            to_date, 
            type, 
            q 
        } = req.query;

        // Primero verificar que el usuario tiene acceso a esta tarjeta
        const cardCheck = await pool.query(
            'SELECT usuario_id FROM tarjeta WHERE id = $1',
            [cardId]
        );

        if (cardCheck.rows.length === 0) {
            return res.status(404).json({
                status: 'error',
                message: 'Tarjeta no encontrada'
            });
        }

        const cardOwner = cardCheck.rows[0].usuario_id;

        if (!isAdmin && cardOwner !== user_id) {
            return res.status(403).json({
                status: 'error',
                message: 'No tienes permisos para ver los movimientos de esta tarjeta'
            });
        }

        // Llamar al stored procedure de movimientos
        const sql = 'SELECT * FROM sp_card_movements_list($1, $2, $3, $4, $5, $6, $7)';
        const values = [
            cardId,
            from_date || null,
            to_date || null,
            type || null,
            q || null,
            parseInt(page),
            parseInt(page_size)
        ];

        const { rows } = await pool.query(sql, values);
        const result = rows[0];

        return res.status(200).json({
            status: 'success',
            message: 'Movimientos obtenidos correctamente',
            data: {
                items: result.items || [],
                pagination: {
                    current_page: result.page,
                    page_size: result.page_size,
                    total_items: result.total,
                    total_pages: Math.ceil(result.total / result.page_size)
                }
            }
        });

    } catch (error) {
        console.error('Error en getCardMovements:', error);
        return res.status(500).json({
            status: 'error',
            message: 'Ocurrió un error al obtener los movimientos de la tarjeta'
        });
    }
};

export const addCardMovement = async (req, res) => {
    try {
        const { cardId } = req.params;
        const { fecha, tipo, descripcion, moneda, monto } = req.body;
        const user_id = req.user.userId;
        const isAdmin = req.user.rol === 'admin' || req.user.rol === 'Admin';

        // Validaciones básicas
        if (!fecha || !tipo || !descripcion || !moneda || !monto) {
            return res.status(400).json({
                status: 'error',
                message: 'Faltan campos obligatorios: fecha, tipo, descripcion, moneda, monto'
            });
        }

        // Verificar permisos de la tarjeta
        const cardCheck = await pool.query(
            'SELECT usuario_id FROM tarjeta WHERE id = $1',
            [cardId]
        );

        if (cardCheck.rows.length === 0) {
            return res.status(404).json({
                status: 'error',
                message: 'Tarjeta no encontrada'
            });
        }

        const cardOwner = cardCheck.rows[0].usuario_id;

        if (!isAdmin && cardOwner !== user_id) {
            return res.status(403).json({
                status: 'error',
                message: 'No tienes permisos para agregar movimientos a esta tarjeta'
            });
        }

        // Llamar al stored procedure
        const sql = 'SELECT * FROM sp_card_movement_add($1, $2, $3, $4, $5, $6)';
        const values = [cardId, fecha, tipo, descripcion, moneda, monto];

        const { rows } = await pool.query(sql, values);
        const result = rows[0];

        return res.status(201).json({
            status: 'success',
            message: 'Movimiento agregado correctamente',
            data: {
                movement_id: result.movement_id,
                nuevo_saldo_tarjeta: result.nuevo_saldo_tarjeta
            }
        });

    } catch (error) {
        console.error('Error en addCardMovement:', error);
        
        if (error.message.includes('límite de crédito')) {
            return res.status(400).json({
                status: 'error',
                message: 'Límite de crédito excedido'
            });
        }

        return res.status(500).json({
            status: 'error',
            message: 'Ocurrió un error al agregar el movimiento'
        });
    }
};