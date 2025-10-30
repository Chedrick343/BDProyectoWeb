CREATE OR REPLACE FUNCTION sp_card_movements_list(
    p_card_id UUID,
    p_from_date TIMESTAMP DEFAULT NULL,
    p_to_date TIMESTAMP DEFAULT NULL,
    p_type UUID DEFAULT NULL,
    p_q TEXT DEFAULT NULL,
    p_page INTEGER DEFAULT 1,
    p_page_size INTEGER DEFAULT 10
)
RETURNS TABLE(
    items JSON,
    total BIGINT,
    page INTEGER,
    page_size INTEGER
) AS $$
DECLARE
    v_total BIGINT;
    v_offset INTEGER;
BEGIN
    -- Calcular offset para paginación
    v_offset := (p_page - 1) * p_page_size;
    
    -- Obtener el total de registros
    SELECT COUNT(*) INTO v_total
    FROM movimiento_tarjeta mt
    WHERE mt.tarjeta_id = p_card_id
    AND (p_from_date IS NULL OR mt.fecha >= p_from_date)
    AND (p_to_date IS NULL OR mt.fecha <= p_to_date)
    AND (p_type IS NULL OR mt.tipo = p_type)
    AND (p_q IS NULL OR mt.descripcion ILIKE '%' || p_q || '%');
    
    -- Retornar los resultados paginados
    RETURN QUERY
    SELECT 
        json_agg(
            json_build_object(
                'id', mt.id,
                'fecha', mt.fecha,
                'tipo', tmt.nombre,
                'descripcion', mt.descripcion,
                'moneda', m.iso,
                'monto', mt.monto
            )
        ) AS items,
        v_total AS total,
        p_page AS page,
        p_page_size AS page_size
    FROM movimiento_tarjeta mt
    INNER JOIN tipo_movimiento_tarjeta tmt ON mt.tipo = tmt.id
    INNER JOIN moneda m ON mt.moneda = m.id
    WHERE mt.tarjeta_id = p_card_id
    AND (p_from_date IS NULL OR mt.fecha >= p_from_date)
    AND (p_to_date IS NULL OR mt.fecha <= p_to_date)
    AND (p_type IS NULL OR mt.tipo = p_type)
    AND (p_q IS NULL OR mt.descripcion ILIKE '%' || p_q || '%')
    ORDER BY mt.fecha DESC
    LIMIT p_page_size
    OFFSET v_offset;
    
END;
$$ LANGUAGE plpgsql;