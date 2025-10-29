CREATE OR REPLACE FUNCTION sp_cards_create(
    p_usuario_id INT,
    p_tipo INT,
    p_numero_enmascarado VARCHAR(30),
    p_fecha_expiracion DATE,
    p_cvv_encriptado VARCHAR(255),
    p_pin_encriptado VARCHAR(255),
    p_moneda VARCHAR(10),
    p_limite_credito DECIMAL(15,2),
    p_saldo_actual DECIMAL(15,2)
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    new_card_id INT;
BEGIN
    INSERT INTO tarjeta (
        numero_tarjeta,
        id_tipo,
        expiracion,
        cvv,
        pin,
        moneda,
        limite,
        saldo,
        id_persona
    ) VALUES (
        p_numero_enmascarado,
        p_tipo,
        p_fecha_expiracion,
        p_cvv_encriptado,
        p_pin_encriptado,
        p_moneda,
        p_limite_credito,
        p_saldo_actual,
        p_usuario_id
    ) RETURNING numero_tarjeta INTO new_card_id;
    
    RETURN new_card_id;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error al crear la tarjeta: %', SQLERRM;
END;
$$;