CREATE OR REPLACE FUNCTION sp_users_get_by_identification(
    p_numero_identificacion VARCHAR
    
)
RETURNS TABLE (
    id_usuario INT,
    nombre_usuario VARCHAR,
    correo_electronico VARCHAR,
    nombre VARCHAR,
    primer_apellido VARCHAR,
    segundo_apellido VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id_usuario,
        u.nombre_usuario,
        u.correo_electronico,
        p.nombre,
        p.primer_apellido,
        p.segundo_apellido
    FROM usuario u
    INNER JOIN persona p ON u.id_persona = p.id_persona
    WHERE p.numero_identificacion = p_numero_identificacion;
END;
$$;
