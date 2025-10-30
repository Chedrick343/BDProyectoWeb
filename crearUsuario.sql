CREATE OR REPLACE FUNCTION sp_users_create(
    p_tipo_identificacion UUID,
    p_identificacion VARCHAR,
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_correo VARCHAR,
    p_telefono VARCHAR,
    p_usuario VARCHAR,
    p_contrasena_hash VARCHAR,
    p_rol UUID
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;
BEGIN

    IF EXISTS (SELECT 1 FROM usuario WHERE identificacion = p_identificacion) THEN
        RAISE EXCEPTION 'Identificación ya registrada';
    END IF;
    IF EXISTS (SELECT 1 FROM usuario WHERE correo = p_correo) THEN
        RAISE EXCEPTION 'Correo ya registrado';
    END IF;
    IF EXISTS (SELECT 1 FROM usuario WHERE usuario = p_usuario) THEN
        RAISE EXCEPTION 'Nombre de usuario ya registrado';
    END IF;

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
        p_tipo_identificacion,
        p_identificacion,
        p_nombre,
        p_apellido,
        p_correo,
        p_telefono,
        p_usuario,
        p_contrasena_hash,
        p_rol
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;
