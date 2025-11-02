DROP FUNCTION IF EXISTS sp_accounts_get_details(UUID);
CREATE OR REPLACE FUNCTION sp_accounts_get_details(
    p_account_id UUID
)
RETURNS TABLE (
    id UUID,
    fecha TIMESTAMP,
    tipo_movimiento VARCHAR,
    descripcion TEXT,
    moneda_iso VARCHAR,
    monto DECIMAL(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT 
        mc.id,
        mc.fecha,
        tmc.nombre AS tipo_movimiento,
        mc.descripcion,
        m.iso AS moneda_iso,
        mc.monto
    FROM movimiento_cuenta mc
    JOIN tipo_movimiento_cuenta tmc ON mc.tipo = tmc.id
    JOIN moneda m ON mc.moneda = m.id
    WHERE mc.cuenta_id = p_account_id
    ORDER BY mc.fecha DESC;
END;
$$;
