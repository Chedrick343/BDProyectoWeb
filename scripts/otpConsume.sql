DROP FUNCTION IF EXISTS sp_otp_consume(
    p_usuario_id UUID,
    p_proposito VARCHAR,
    p_codigo_hash VARCHAR
);

CREATE OR REPLACE FUNCTION sp_otp_consume(
    p_usuario_id UUID,
    p_proposito VARCHAR,
    p_codigo_hash VARCHAR,
    p_nueva_contrasena_hash VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;
BEGIN
    -- Buscar OTP válido (no consumido, no expirado) que coincida con hash y propósito
    SELECT id INTO v_id
    FROM otp
    WHERE usuario_id = p_usuario_id
      AND proposito = p_proposito
      AND codigo_hash = p_codigo_hash
      AND fecha_consumido IS NULL
      AND fecha_expiracion >= NOW()
    LIMIT 1;

    -- Si no se encontró un OTP válido
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
        

            UPDATE otp
            SET fecha_consumido = NOW()
            WHERE id = v_id;

    UPDATE usuario
    SET contrasena_hash = p_nueva_contrasena_hash
    WHERE id = p_usuario_id;

    RETURN TRUE;
END;
$$;
