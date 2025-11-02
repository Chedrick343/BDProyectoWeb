CREATE OR REPLACE FUNCTION sp_accounts_set_status(
    p_account_id UUID,
    p_nuevo_estado_nombre VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo DECIMAL(18,2);
    v_estado_id UUID;
    v_estado_nombre_db TEXT;
BEGIN
    -- Verificar que la cuenta exista
    SELECT saldo INTO v_saldo FROM cuenta WHERE id = p_account_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta no encontrada';
    END IF;

    -- Buscar el ID del nuevo estado según el nombre
    SELECT id, nombre INTO v_estado_id, v_estado_nombre_db
    FROM estado_cuenta
    WHERE LOWER(nombre) = LOWER(p_nuevo_estado_nombre);

    IF v_estado_id IS NULL THEN
        RAISE EXCEPTION 'Estado "%" no existe', p_nuevo_estado_nombre;
    END IF;

    -- Regla: no se puede cerrar cuenta si saldo distinto de 0
    IF LOWER(v_estado_nombre_db) IN ('cerrada', 'closed')
       AND abs(coalesce(v_saldo, 0)) > 0.0 THEN
        RAISE EXCEPTION 'No se puede cerrar la cuenta con saldo diferente de cero (saldo actual: %)', v_saldo;
    END IF;

    -- Actualizar el estado
    UPDATE cuenta
    SET estado = v_estado_id,
        fecha_actualizacion = NOW()
    WHERE id = p_account_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;
