CREATE OR REPLACE FUNCTION sp_users_delete(
    p_admin_executor UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_name TEXT;
    v_account UUID;
BEGIN
    -- Verificar que el ejecutor sea admin
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

    IF p_admin_executor = p_user_id THEN
        RAISE EXCEPTION 'No se permite que un admin se elimine a si mismo';
    END IF;

    -- 1) Eliminar movimientos de cuentas de las cuentas del usuario
    DELETE FROM movimiento_cuenta
    WHERE cuenta_id IN (SELECT id FROM cuenta WHERE usuario_id = p_user_id);

    -- 2) Eliminar transferencias que involucren esas cuentas
    DELETE FROM transferencia
    WHERE cuenta_origen IN (SELECT id FROM cuenta WHERE usuario_id = p_user_id)
       OR cuenta_destino IN (SELECT id FROM cuenta WHERE usuario_id = p_user_id);

    -- 3) Eliminar cuentas del usuario
    DELETE FROM cuenta WHERE usuario_id = p_user_id;

    -- 4) Eliminar movimientos de tarjeta y tarjetas del usuario
    DELETE FROM movimiento_tarjeta
    WHERE tarjeta_id IN (SELECT id FROM tarjeta WHERE usuario_id = p_user_id);

    DELETE FROM tarjeta WHERE usuario_id = p_user_id;

    -- 5) Eliminar OTPs del usuario
    DELETE FROM otp WHERE usuario_id = p_user_id;

    -- 6) Finalmente eliminar al usuario
    DELETE FROM usuario WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;
