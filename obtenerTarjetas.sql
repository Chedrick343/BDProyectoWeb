CREATE OR REPLACE FUNCTION sp_cards_get(
    p_owner_id INT DEFAULT NULL,
    p_card_id VARCHAR(30) DEFAULT NULL
)
RETURNS TABLE(
    numero_tarjeta VARCHAR(30),
    id_tipo INT,
    expiracion DATE,
    moneda VARCHAR(10),
    limite DECIMAL(15,2),
    saldo DECIMAL(15,2),
    id_persona INT,
    nombre_tipo VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_card_id IS NOT NULL THEN
        RETURN QUERY
        SELECT 
            t.numero_tarjeta,
            t.id_tipo,
            t.expiracion,
            t.moneda,
            t.limite,
            t.saldo,
            t.id_persona,
            tt.nombre_tipo
        FROM tarjeta t
        INNER JOIN tipo_tarjeta tt ON t.id_tipo = tt.id_tipo
        WHERE t.numero_tarjeta = p_card_id
        AND (p_owner_id IS NULL OR t.id_persona = p_owner_id);
    ELSE
        RETURN QUERY
        SELECT 
            t.numero_tarjeta,
            t.id_tipo,
            t.expiracion,
            t.moneda,
            t.limite,
            t.saldo,
            t.id_persona,
            tt.nombre_tipo
        FROM tarjeta t
        INNER JOIN tipo_tarjeta tt ON t.id_tipo = tt.id_tipo
        WHERE p_owner_id IS NULL OR t.id_persona = p_owner_id;
    END IF;
END;
$$;