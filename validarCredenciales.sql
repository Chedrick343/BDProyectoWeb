CREATE OR REPLACE FUNCTION sp_auth_user_get_by_username_or_email(
    p_username_or_email VARCHAR
)
RETURNS TABLE (
    user_id UUID,
    contrasena_hash VARCHAR,
    rol UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.contrasena_hash, u.rol
    FROM usuario u
    WHERE u.usuario = p_username_or_email OR u.correo = p_username_or_email
    LIMIT 1;
END;
$$;
