CREATE OR REPLACE PROCEDURE sp_users_delete(
    p_admin_id INT,      -- ID del usuario que ejecuta
    p_id_usuario INT     -- ID del usuario a eliminar
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin_role VARCHAR;
    v_id_persona INT;
BEGIN

    SELECT role INTO v_admin_role
    FROM usuario
    WHERE id_usuario = p_admin_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Error: el usuario administrador no existe.';
        RETURN;
    END IF;


    IF v_admin_role <> 'admin' THEN
        RAISE NOTICE 'Acceso denegado: el usuario % no tiene permisos de administrador.', p_admin_id;
        RETURN;
    END IF;

    IF p_admin_id = p_id_usuario THEN
        RAISE NOTICE 'No puedes eliminar tu propia cuenta.';
        RETURN;
    END IF;


    SELECT id_persona INTO v_id_persona
    FROM usuario
    WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE NOTICE 'No se encontró el usuario con id %', p_id_usuario;
        RETURN;
    END IF;


    DELETE FROM movimientos_cuenta
    WHERE numero_cuenta IN (
        SELECT numero_cuenta FROM cuenta WHERE id_persona = v_id_persona
    );


    DELETE FROM movimientos_tarjeta
    WHERE id_tarjeta IN (
        SELECT numero_tarjeta FROM tarjeta WHERE id_persona = v_id_persona
    );


    DELETE FROM transferencia
    WHERE cuenta_origen IN (
        SELECT numero_cuenta FROM cuenta WHERE id_persona = v_id_persona
    )
    OR cuenta_destino IN (
        SELECT numero_cuenta FROM cuenta WHERE id_persona = v_id_persona
    );


    DELETE FROM cuenta
    WHERE id_persona = v_id_persona;


    DELETE FROM tarjeta
    WHERE id_persona = v_id_persona;


    DELETE FROM usuario
    WHERE id_usuario = p_id_usuario;

    DELETE FROM persona
    WHERE id_persona = v_id_persona;

    RAISE NOTICE 'Usuario %, persona %, y todos los registros asociados fueron eliminados correctamente.', p_id_usuario, v_id_persona;
END;
$$;
