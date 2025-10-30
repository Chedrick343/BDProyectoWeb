CREATE OR REPLACE FUNCTION sp_accounts_get(
    p_owner_id UUID DEFAULT NULL,
    p_account_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    iban VARCHAR,
    alias VARCHAR,
    tipo_cuenta VARCHAR,
    moneda_iso VARCHAR,
    saldo DECIMAL(18,2),
    estado VARCHAR,
    fecha_creacion TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_account_id IS NOT NULL THEN
        RETURN QUERY
        SELECT c.id, c.iban, c.alias, tc.nombre, m.iso, c.saldo, ec.nombre, c.fecha_creacion
        FROM cuenta c
        JOIN tipo_cuenta tc ON c.tipo_cuenta = tc.id
        JOIN moneda m ON c.moneda = m.id
        JOIN estado_cuenta ec ON c.estado = ec.id
        WHERE c.id = p_account_id;
        RETURN;
    END IF;

    IF p_owner_id IS NOT NULL THEN
        RETURN QUERY
        SELECT c.id, c.iban, c.alias, tc.nombre, m.iso, c.saldo, ec.nombre, c.fecha_creacion
        FROM cuenta c
        JOIN tipo_cuenta tc ON c.tipo_cuenta = tc.id
        JOIN moneda m ON c.moneda = m.id
        JOIN estado_cuenta ec ON c.estado = ec.id
        WHERE c.usuario_id = p_owner_id;
        RETURN;
    END IF;


    RAISE EXCEPTION 'Debe proporcionar owner_id o account_id';
END;
$$;
