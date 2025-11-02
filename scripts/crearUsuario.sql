DROP FUNCTION IF EXISTS sp_users_create(
    p_tipo_identificacion_nombre VARCHAR,
    p_identificacion VARCHAR,
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_correo VARCHAR,
    p_telefono VARCHAR,
    p_usuario VARCHAR,
    p_contrasena_hash VARCHAR,
    p_rol_nombre VARCHAR
);
CREATE OR REPLACE FUNCTION sp_users_create(
    p_tipo_identificacion_nombre VARCHAR,
    p_identificacion VARCHAR,
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_correo VARCHAR,
    p_telefono VARCHAR,
    p_usuario VARCHAR,
    p_contrasena_hash VARCHAR,
    p_rol_nombre VARCHAR
)
RETURNS TABLE (user_id UUID)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;
    v_tipo_identificacion_id UUID;
    v_rol_id UUID;
BEGIN
    -- Obtener ID del tipo de identificación
    SELECT id INTO v_tipo_identificacion_id
    FROM tipo_identificacion
    WHERE LOWER(nombre) = LOWER(p_tipo_identificacion_nombre);

    IF v_tipo_identificacion_id IS NULL THEN
        RAISE EXCEPTION 'Tipo de identificación "%" no existe', p_tipo_identificacion_nombre;
    END IF;

    -- Obtener ID del rol
    SELECT id INTO v_rol_id
    FROM rol
    WHERE LOWER(nombre) = LOWER(p_rol_nombre);

    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'Rol "%" no existe', p_rol_nombre;
    END IF;

    -- Validaciones de unicidad
    IF EXISTS (SELECT 1 FROM usuario WHERE identificacion = p_identificacion) THEN
        RAISE EXCEPTION 'Identificación "%" ya registrada', p_identificacion;
    END IF;

    IF EXISTS (SELECT 1 FROM usuario WHERE LOWER(correo) = LOWER(p_correo)) THEN
        RAISE EXCEPTION 'Correo "%" ya registrado', p_correo;
    END IF;

    IF EXISTS (SELECT 1 FROM usuario WHERE LOWER(usuario) = LOWER(p_usuario)) THEN
        RAISE EXCEPTION 'Nombre de usuario "%" ya registrado', p_usuario;
    END IF;

    -- Insertar el usuario
    INSERT INTO usuario (
        tipo_identificacion,
        identificacion,
        nombre,
        apellido,
        correo,
        telefono,
        usuario,
        contrasena_hash,
        rol
    )
    VALUES (
        v_tipo_identificacion_id,
        p_identificacion,
        p_nombre,
        p_apellido,
        p_correo,
        p_telefono,
        p_usuario,
        p_contrasena_hash,
        v_rol_id
    )
    RETURNING id INTO v_id;

    -- Retornar como tabla
    RETURN QUERY SELECT v_id AS user_id;
END;
$$;
