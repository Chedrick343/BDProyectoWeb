CREATE OR REPLACE FUNCTION sp_users_get_by_identification(
    p_identificacion VARCHAR
)
RETURNS TABLE (
    id UUID,
    nombre VARCHAR,
    apellido VARCHAR,
    correo VARCHAR,
    usuario VARCHAR,
    rol UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.nombre, u.apellido, u.correo, u.usuario, u.rol
    FROM usuario u
    WHERE u.identificacion = p_identificacion
    LIMIT 1;
END;
$$;
