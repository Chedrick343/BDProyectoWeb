CREATE OR REPLACE FUNCTION sp_accounts_create(
    p_usuario_id UUID,
    p_iban VARCHAR,
    p_alias VARCHAR,
    p_tipo_nombre VARCHAR,      -- ahora recibe el nombre del tipo de cuenta
    p_moneda_iso VARCHAR,       -- ahora recibe el código ISO de la moneda
    p_saldo_inicial DECIMAL(18,2),
    p_estado_nombre VARCHAR     -- ahora recibe el nombre del estado
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;
    v_tipo_id UUID;
    v_moneda_id UUID;
    v_estado_id UUID;
BEGIN
    -- Validar existencia de usuario
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_usuario_id) THEN
        RAISE EXCEPTION 'Usuario no existe';
    END IF;

    -- Obtener ID del tipo de cuenta
    SELECT id INTO v_tipo_id FROM tipo_cuenta WHERE nombre = p_tipo_nombre;
    IF v_tipo_id IS NULL THEN
        RAISE EXCEPTION 'Tipo de cuenta "%" no existe', p_tipo_nombre;
    END IF;

    -- Obtener ID de la moneda
    SELECT id INTO v_moneda_id FROM moneda WHERE iso = p_moneda_iso;
    IF v_moneda_id IS NULL THEN
        RAISE EXCEPTION 'Moneda "%" no existe', p_moneda_iso;
    END IF;

    -- Obtener ID del estado
    SELECT id INTO v_estado_id FROM estado_cuenta WHERE nombre = p_estado_nombre;
    IF v_estado_id IS NULL THEN
        RAISE EXCEPTION 'Estado de cuenta "%" no existe', p_estado_nombre;
    END IF;

    -- Insertar cuenta
    INSERT INTO cuenta (
        usuario_id, iban, alias, tipo_cuenta, moneda, saldo, estado
    )
    VALUES (
        p_usuario_id,
        p_iban,
        p_alias,
        v_tipo_id,
        v_moneda_id,
        p_saldo_inicial,
        v_estado_id
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;
