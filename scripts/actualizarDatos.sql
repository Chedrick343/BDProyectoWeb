DROP FUNCTION IF EXISTS sp_users_update(UUID, UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID, VARCHAR);

CREATE OR REPLACE FUNCTION sp_users_update(
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
BEGIN
    -- Validaciones de unicidad si se cambia correo o usuario
    IF p_correo IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE LOWER(correo) = LOWER(p_correo) AND id <> p_user_id) THEN
            RAISE EXCEPTION 'Correo "%" ya está registrado por otro usuario', p_correo;
        END IF;
    END IF;

    IF p_usuario IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE LOWER(usuario) = LOWER(p_usuario) AND id <> p_user_id) THEN
            RAISE EXCEPTION 'Nombre de usuario "%" ya está registrado por otro usuario', p_usuario;
        END IF;
    END IF;

    -- Actualizar usuario con los campos provistos
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
