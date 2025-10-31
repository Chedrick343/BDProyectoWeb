CREATE OR REPLACE FUNCTION sp_accounts_set_status(
    p_account_id UUID,
    p_nuevo_estado UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo DECIMAL(18,2);
    v_estado_name TEXT;
BEGIN
    SELECT saldo INTO v_saldo FROM cuenta WHERE id = p_account_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta no encontrada';
    END IF;

    SELECT nombre INTO v_estado_name FROM estado_cuenta WHERE id = p_nuevo_estado;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Estado desconocido';
    END IF;

    IF lower(v_estado_name) IN ('cerrada','closed') AND abs(coalesce(v_saldo,0)) > 0.0 THEN
        RAISE EXCEPTION 'No se puede cerrar la cuenta con saldo diferente de cero';
    END IF;

    UPDATE cuenta
    SET estado = p_nuevo_estado,
        fecha_actualizacion = NOW()
    WHERE id = p_account_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;
