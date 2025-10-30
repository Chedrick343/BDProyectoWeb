CREATE OR REPLACE FUNCTION sp_card_movement_add(
    p_card_id UUID,
    p_fecha TIMESTAMP,
    p_tipo UUID,
    p_descripcion TEXT,
    p_moneda UUID,
    p_monto DECIMAL(18,2)
)
RETURNS TABLE(
    movement_id UUID,
    nuevo_saldo_tarjeta DECIMAL(18,2)
) AS $$
DECLARE
    v_movement_id UUID;
    v_nuevo_saldo DECIMAL(18,2);
    v_tipo_movimiento VARCHAR(50);
BEGIN
    -- Obtener el tipo de movimiento para determinar si es compra o pago
    SELECT nombre INTO v_tipo_movimiento
    FROM tipo_movimiento_tarjeta
    WHERE id = p_tipo;
    
    -- Insertar el movimiento
    INSERT INTO movimiento_tarjeta (
        tarjeta_id,
        fecha,
        tipo,
        descripcion,
        moneda,
        monto
    ) VALUES (
        p_card_id,
        p_fecha,
        p_tipo,
        p_descripcion,
        p_moneda,
        p_monto
    ) RETURNING id INTO v_movement_id;
    
    -- Actualizar saldo de la tarjeta según el tipo de movimiento
    IF v_tipo_movimiento = 'Compra' THEN
        UPDATE tarjeta 
        SET saldo_actual = saldo_actual + p_monto,
            fecha_actualizacion = NOW()
        WHERE id = p_card_id
        RETURNING saldo_actual INTO v_nuevo_saldo;
    ELSIF v_tipo_movimiento = 'Pago' THEN
        UPDATE tarjeta 
        SET saldo_actual = saldo_actual - p_monto,
            fecha_actualizacion = NOW()
        WHERE id = p_card_id
        RETURNING saldo_actual INTO v_nuevo_saldo;
    END IF;
    
    -- Retornar resultados
    RETURN QUERY SELECT v_movement_id, v_nuevo_saldo;
    
END;
$$ LANGUAGE plpgsql;