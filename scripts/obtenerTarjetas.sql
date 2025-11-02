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
        COALESCE(
            json_agg(
                json_build_object(
                    'id', sub.id,
                    'usuario_id', sub.usuario_id,
                    'tipo', sub.tipo_nombre,
                    'numero_enmascarado', sub.numero_enmascarado,
                    'fecha_expiracion', sub.fecha_expiracion,
                    'moneda', sub.moneda_iso,
                    'limite_credito', sub.limite_credito,
                    'saldo_actual', sub.saldo_actual,
                    'fecha_creacion', sub.fecha_creacion
                )
            ),
            '[]'::json
        ) AS cards
    FROM (
        SELECT 
            t.id,
            t.usuario_id,
            tt.nombre as tipo_nombre,
            t.numero_enmascarado,
            t.fecha_expiracion,
            m.iso as moneda_iso,
            t.limite_credito,
            t.saldo_actual,
            t.fecha_creacion
        FROM tarjeta t
        INNER JOIN tipo_tarjeta tt ON t.tipo = tt.id
        INNER JOIN moneda m ON t.moneda = m.id
        WHERE (p_owner_id IS NULL OR t.usuario_id = p_owner_id)
        AND (p_card_id IS NULL OR t.id = p_card_id)
    ) AS sub;
END;
$$ LANGUAGE plpgsql;