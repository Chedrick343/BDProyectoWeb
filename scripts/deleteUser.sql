CREATE OR REPLACE FUNCTION sp_users_delete(
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1️⃣ Eliminar movimientos de cuentas del usuario
    DELETE FROM movimiento_cuenta
    WHERE cuenta_id IN (
        SELECT id FROM cuenta WHERE usuario_id = p_user_id
    );

    -- 2️⃣ Eliminar transferencias que involucren las cuentas del usuario
    DELETE FROM transferencia
    WHERE cuenta_origen IN (
        SELECT id FROM cuenta WHERE usuario_id = p_user_id
    )
    OR cuenta_destino IN (
        SELECT id FROM cuenta WHERE usuario_id = p_user_id
    );

    -- 3️⃣ Eliminar cuentas del usuario
    DELETE FROM cuenta WHERE usuario_id = p_user_id;

    -- 4️⃣ Eliminar movimientos de tarjetas y tarjetas del usuario
    DELETE FROM movimiento_tarjeta
    WHERE tarjeta_id IN (
        SELECT id FROM tarjeta WHERE usuario_id = p_user_id
    );

    DELETE FROM tarjeta WHERE usuario_id = p_user_id;

    -- 5️⃣ Eliminar OTPs asociados al usuario
    DELETE FROM otp WHERE usuario_id = p_user_id;

    -- 6️⃣ Finalmente eliminar al usuario
    DELETE FROM usuario WHERE id = p_user_id;

    -- Si no se encontró el usuario, retornar FALSE
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Si todo salió bien, retornar TRUE
    RETURN TRUE;
END;
$$;
