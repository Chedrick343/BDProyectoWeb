CREATE OR REPLACE FUNCTION sp_card_movements_list(
    p_card_id VARCHAR(30),
    p_from_date TIMESTAMP DEFAULT NULL,
    p_to_date TIMESTAMP DEFAULT NULL,
    p_type VARCHAR(20) DEFAULT NULL,
    p_search VARCHAR(255) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_page_size INT DEFAULT 10
)
RETURNS TABLE(
    id INT,
    id_tarjeta VARCHAR(30),
    fecha_movimiento TIMESTAMP,
    tipo_movimiento VARCHAR(20),
    descripcion VARCHAR(255),
    moneda VARCHAR(10),
    saldo_movimiento DECIMAL(15,2),
    total_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mt.id,
        mt.id_tarjeta,
        mt.fecha_movimiento,
        mt.tipo_movimiento,
        mt.descripcion,
        mt.moneda,
        mt.saldo_movimiento,
        COUNT(*) OVER() as total_count
    FROM movimientos_tarjeta mt
    WHERE mt.id_tarjeta = p_card_id
    AND (p_from_date IS NULL OR mt.fecha_movimiento >= p_from_date)
    AND (p_to_date IS NULL OR mt.fecha_movimiento <= p_to_date)
    AND (p_type IS NULL OR mt.tipo_movimiento = p_type)
    AND (p_search IS NULL OR mt.descripcion ILIKE '%' || p_search || '%')
    ORDER BY mt.fecha_movimiento DESC
    LIMIT p_page_size
    OFFSET (p_page - 1) * p_page_size;
END;
$$;