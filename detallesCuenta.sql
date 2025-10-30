CREATE OR REPLACE FUNCTION fn_account_get(
    p_id_usuario_solicitante INT,
    p_numero_cuenta VARCHAR(30)
)
RETURNS TABLE (
    numero_cuenta VARCHAR(30),
    alias VARCHAR(50),
    tipo_cuenta VARCHAR(20),
    moneda VARCHAR(10),
    saldo_disponible DECIMAL(15,2),
    nombre_propietario VARCHAR(100),
    primer_apellido VARCHAR(100),
    segundo_apellido VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_solicitante VARCHAR;
    v_id_persona_solicitante INT;
    v_id_persona_cuenta INT;
BEGIN
    -- Obtener rol e id_persona del solicitante
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

    -- Validar permisos: admin o dueño de la cuenta
    IF v_role_solicitante <> 'admin' AND v_id_persona_solicitante <> v_id_persona_cuenta THEN
        RAISE EXCEPTION 'Acceso denegado: el usuario % no tiene permisos para consultar la cuenta %.',
                        p_id_usuario_solicitante, p_numero_cuenta;
    END IF;

    -- Devolver los datos de la cuenta con el nombre del propietario
    RETURN QUERY
    SELECT 
        c.numero_cuenta,
        c.alias,
        c.tipo_cuenta,
        c.moneda,
        c.saldo_disponible,
        p.nombre,
        p.primer_apellido,
        p.segundo_apellido
    FROM cuenta c
    INNER JOIN persona p ON c.id_persona = p.id_persona
    WHERE c.numero_cuenta = p_numero_cuenta;

END;
$$;
