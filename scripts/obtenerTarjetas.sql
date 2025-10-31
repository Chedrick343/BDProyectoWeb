CREATE OR REPLACE FUNCTION sp_cards_get(
    p_owner_id UUID DEFAULT NULL,
    p_card_id UUID DEFAULT NULL
)
RETURNS TABLE(
    cards JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        json_agg(
            json_build_object(
                'id', t.id,
                'usuario_id', t.usuario_id,
                'tipo', tt.nombre,
                'numero_enmascarado', t.numero_enmascarado,
                'fecha_expiracion', t.fecha_expiracion,
                'moneda', m.iso,
                'limite_credito', t.limite_credito,
                'saldo_actual', t.saldo_actual,
                'fecha_creacion', t.fecha_creacion
            )
        ) AS cards
    FROM tarjeta t
    INNER JOIN tipo_tarjeta tt ON t.tipo = tt.id
    INNER JOIN moneda m ON t.moneda = m.id
    WHERE (p_owner_id IS NULL OR t.usuario_id = p_owner_id)
    AND (p_card_id IS NULL OR t.id = p_card_id);
END;
$$ LANGUAGE plpgsql;