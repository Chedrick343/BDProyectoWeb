CREATE OR REPLACE FUNCTION sp_api_key_is_active(
    p_api_key_hash VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_active BOOLEAN;
BEGIN
    SELECT activa INTO v_active
    FROM api_key
    WHERE clave_hash = p_api_key_hash
    LIMIT 1;

    RETURN COALESCE(v_active, FALSE);
END;
$$;
