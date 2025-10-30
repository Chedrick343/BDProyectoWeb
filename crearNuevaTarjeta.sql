CREATE OR REPLACE FUNCTION sp_cards_create(
    p_usuario_id UUID,
    p_tipo UUID,
    p_numero_enmascarado VARCHAR(25),
    p_fecha_expiracion VARCHAR(5),
    p_cvv_encriptado VARCHAR(255),
    p_pin_encriptado VARCHAR(255),
    p_moneda UUID,
    p_limite_credito DECIMAL(18,2),
    p_saldo_actual DECIMAL(18,2)
)
RETURNS UUID AS $$
DECLARE
    v_card_id UUID;
BEGIN
    INSERT INTO tarjeta (
        usuario_id,
        tipo,
        numero_enmascarado,
        fecha_expiracion,
        cvv_hash,
        pin_hash,
        moneda,
        limite_credito,
        saldo_actual
    ) VALUES (
        p_usuario_id,
        p_tipo,
        p_numero_enmascarado,
        p_fecha_expiracion,
        p_cvv_encriptado,
        p_pin_encriptado,
        p_moneda,
        p_limite_credito,
        p_saldo_actual
    ) RETURNING id INTO v_card_id;
    
    RETURN v_card_id;
END;
$$ LANGUAGE plpgsql;