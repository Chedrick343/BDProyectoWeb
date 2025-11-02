CREATE OR REPLACE FUNCTION sp_otp_get(
    p_usuario_id UUID,
    p_proposito VARCHAR
)
RETURNS TABLE (
    id UUID,
    proposito VARCHAR,
    codigo_hash VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT o.id, o.proposito, o.codigo_hash
    FROM otp o
    WHERE o.usuario_id = p_usuario_id
      AND o.proposito = p_proposito
      AND o.fecha_consumido IS NULL
      AND o.fecha_expiracion > NOW()
    LIMIT 1;
END;
$$;
