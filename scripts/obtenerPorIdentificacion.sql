DROP FUNCTION IF EXISTS sp_users_get_by_identification(VARCHAR);
CREATE OR REPLACE FUNCTION sp_users_get_by_identification(
    p_identificacion VARCHAR
)
RETURNS TABLE (
    id UUID,
    identificacion VARCHAR,
    nombre VARCHAR,
    apellido VARCHAR,
    correo VARCHAR,
    usuario VARCHAR,
    nombre_rol VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.identificacion, u.nombre, u.apellido, u.correo, u.usuario, r.nombre AS nombre_rol
    FROM usuario u
    INNER JOIN rol r ON u.rol = r.id
    WHERE u.identificacion = p_identificacion
    LIMIT 1;
END;
$$;
