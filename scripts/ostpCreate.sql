CREATE OR REPLACE FUNCTION sp_otp_create(
    p_usuario_id UUID,
    p_proposito VARCHAR,
    p_expires_in_seconds INT,
    p_codigo_hash VARCHAR
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;
    v_exp TIMESTAMP;
BEGIN
    v_exp := NOW() + (p_expires_in_seconds || ' seconds')::interval;

    INSERT INTO otp (
        usuario_id,
        codigo_hash,
        proposito,
        fecha_expiracion
    )
    VALUES (
        p_usuario_id,
        p_codigo_hash,
        p_proposito,
        v_exp
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;
