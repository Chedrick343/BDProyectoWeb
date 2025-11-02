CREATE OR REPLACE FUNCTION sp_auth_user_get_by_username_or_email(
    p_username_or_email VARCHAR
)
RETURNS TABLE (
    user_id UUID,
    contrasena_hash VARCHAR,
    rol_nombre VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id AS user_id,
        u.contrasena_hash,
        r.nombre AS rol_nombre
    FROM usuario u
    JOIN rol r ON u.rol = r.id
    WHERE u.usuario = p_username_or_email 
       OR u.correo = p_username_or_email
    LIMIT 1;
END;
$$;
