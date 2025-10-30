CREATE OR REPLACE FUNCTION sp_users_update(
    p_admin_executor UUID,
    p_user_id UUID,
    p_nombre VARCHAR DEFAULT NULL,
    p_apellido VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_usuario VARCHAR DEFAULT NULL,
    p_rol UUID DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_name TEXT;
BEGIN
    -- Verificar que el ejecutor sea admin (obtenemos nombre del rol)
    SELECT r.nombre INTO v_role_name
    FROM usuario u
    JOIN rol r ON u.rol = r.id
    WHERE u.id = p_admin_executor;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario executor no existe';
    END IF;

    IF v_role_name <> 'Admin' AND v_role_name <> 'admin' THEN
        RAISE EXCEPTION 'Acceso denegado: el usuario executor no es admin';
    END IF;

    -- Validaciones de unicidad si se cambia correo o usuario
    IF p_correo IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE correo = p_correo AND id <> p_user_id) THEN
            RAISE EXCEPTION 'Correo ya registrado por otro usuario';
        END IF;
    END IF;

    IF p_usuario IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE usuario = p_usuario AND id <> p_user_id) THEN
            RAISE EXCEPTION 'Nombre de usuario ya registrado por otro usuario';
        END IF;
    END IF;

    -- Ejecutar update
    UPDATE usuario
    SET
        nombre = COALESCE(p_nombre, nombre),
        apellido = COALESCE(p_apellido, apellido),
        correo = COALESCE(p_correo, correo),
        usuario = COALESCE(p_usuario, usuario),
        rol = COALESCE(p_rol, rol),
        telefono = COALESCE(p_telefono, telefono),
        fecha_actualizacion = NOW()
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;
