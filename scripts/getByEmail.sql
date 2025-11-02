CREATE OR REPLACE FUNCTION sp_users_get_by_email(
    p_correo VARCHAR
)
RETURNS TABLE (
    id UUID,
    nombre VARCHAR,
    apellido VARCHAR,
    correo VARCHAR,
    usuario VARCHAR,
    rol_nombre VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.nombre, u.apellido, u.correo, u.usuario, r.nombre
    FROM usuario u
    INNER JOIN rol r ON u.rol = r.id
    WHERE u.correo = p_correo
    LIMIT 1;
END;
$$;
