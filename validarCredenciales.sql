CREATE OR REPLACE FUNCTION sp_auth_user_get_by_username_or_email(
    p_login VARCHAR,        -- puede ser nombre de usuario o correo
    p_contrasena VARCHAR
)
RETURNS TABLE (
    id_usuario INT,
    id_persona INT,
    nombre VARCHAR,
    primer_apellido VARCHAR,
    segundo_apellido VARCHAR,
    correo_electronico VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id_usuario,
        p.id_persona,
        p.nombre,
        p.primer_apellido,
        p.segundo_apellido,
        u.correo_electronico
    FROM usuario u
    INNER JOIN persona p ON u.id_persona = p.id_persona
    WHERE (u.nombre_usuario = p_login OR u.correo_electronico = p_login)
      AND u.contrasena = crypt(p_contrasena, u.contrasena);
END;
$$;
