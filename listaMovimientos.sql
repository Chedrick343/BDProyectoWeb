CREATE OR REPLACE FUNCTION fn_account_movements_list(
    p_id_usuario_solicitante INT,
    p_numero_cuenta VARCHAR(30),
    p_fecha_inicio TIMESTAMP DEFAULT NULL,
    p_fecha_fin TIMESTAMP DEFAULT NULL,
    p_tipo_movimiento VARCHAR(20) DEFAULT NULL,
    p_busqueda VARCHAR(255) DEFAULT NULL
)
RETURNS TABLE (
    id_movimiento INT,
    fecha_movimiento TIMESTAMP,
    tipo_movimiento VARCHAR(20),
    descripcion VARCHAR(255),
    moneda VARCHAR(10),
    saldo_movimiento DECIMAL(15,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_solicitante VARCHAR;
    v_id_persona_solicitante INT;
    v_id_persona_cuenta INT;
BEGIN
    -- Obtener datos del usuario solicitante
    SELECT u.role, u.id_persona
    INTO v_role_solicitante, v_id_persona_solicitante
    FROM usuario u
    WHERE u.id_usuario = p_id_usuario_solicitante;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario solicitante con id % no existe.', p_id_usuario_solicitante;
    END IF;

    -- Verificar que la cuenta exista y obtener su propietario
    SELECT id_persona INTO v_id_persona_cuenta
    FROM cuenta
    WHERE numero_cuenta = p_numero_cuenta;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La cuenta con número % no existe.', p_numero_cuenta;
    END IF;

    -- Validar permisos (solo admin o dueño)
    IF v_role_solicitante <> 'admin' AND v_id_persona_solicitante <> v_id_persona_cuenta THEN
        RAISE EXCEPTION 'Acceso denegado: el usuario % no tiene permisos para ver los movimientos de la cuenta %.',
                        p_id_usuario_solicitante, p_numero_cuenta;
    END IF;

    -- Devolver movimientos con filtros opcionales
    RETURN QUERY
    SELECT
        m.id AS id_movimiento,
        m.fecha_movimiento,
        m.tipo_movimiento,
        m.descripcion,
        m.moneda,
        m.saldo_movimiento
    FROM movimientos_cuenta m
    WHERE m.numero_cuenta = p_numero_cuenta
      AND (p_fecha_inicio IS NULL OR m.fecha_movimiento >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR m.fecha_movimiento <= p_fecha_fin)
      AND (p_tipo_movimiento IS NULL OR m.tipo_movimiento ILIKE p_tipo_movimiento)
      AND (p_busqueda IS NULL OR m.descripcion ILIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY m.fecha_movimiento DESC;

END;
$$;
