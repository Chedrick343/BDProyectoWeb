CREATE OR REPLACE FUNCTION fn_accounts_get(
    p_id_usuario_solicitante INT,
    p_id_usuario_objetivo INT
)
RETURNS TABLE (
    numero_cuenta VARCHAR(30),
    alias VARCHAR(50),
    tipo_cuenta VARCHAR(20),
    moneda VARCHAR(10),
    saldo_disponible DECIMAL(15,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_solicitante VARCHAR;
    v_id_persona_objetivo INT;
BEGIN

    SELECT role INTO v_role_solicitante
    FROM usuario
    WHERE id_usuario = p_id_usuario_solicitante;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario solicitante con id % no existe.', p_id_usuario_solicitante;
    END IF;


    SELECT id_persona INTO v_id_persona_objetivo
    FROM usuario
    WHERE id_usuario = p_id_usuario_objetivo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario objetivo con id % no existe.', p_id_usuario_objetivo;
    END IF;


    IF v_role_solicitante <> 'admin' AND p_id_usuario_solicitante <> p_id_usuario_objetivo THEN
        RAISE EXCEPTION 'Acceso denegado: el usuario % no tiene permisos para ver las cuentas de %.',
                        p_id_usuario_solicitante, p_id_usuario_objetivo;
    END IF;


    RETURN QUERY
    SELECT
        numero_cuenta,
        alias,
        tipo_cuenta,
        moneda,
        saldo_disponible
    FROM cuenta
    WHERE id_persona = v_id_persona_objetivo;
END;
$$;
