DROP FUNCTION IF EXISTS sp_accounts_get(UUID, UUID);
CREATE OR REPLACE FUNCTION sp_accounts_get(
    p_owner_id UUID,
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
    -- Validar que el owner_id sea obligatorio
    IF p_owner_id IS NULL THEN
        RAISE EXCEPTION 'Debe proporcionar el ID del propietario (p_owner_id)';
    END IF;

    -- Si se especifica una cuenta, traer solo esa (y validar que sea del usuario)
    IF p_account_id IS NOT NULL THEN
        RETURN QUERY
        SELECT c.id, c.iban, c.alias, tc.nombre AS tipo_cuenta, m.iso AS moneda_iso, 
               c.saldo, ec.nombre AS estado, c.fecha_creacion
        FROM cuenta c
        JOIN tipo_cuenta tc ON c.tipo_cuenta = tc.id
        JOIN moneda m ON c.moneda = m.id
        JOIN estado_cuenta ec ON c.estado = ec.id
        WHERE c.id = p_account_id
          AND c.usuario_id = p_owner_id; -- seguridad: solo su propia cuenta
        RETURN;
    END IF;

    -- Si no se especifica una cuenta, traer todas las del usuario
    RETURN QUERY
    SELECT c.id, c.iban, c.alias, tc.nombre AS tipo_cuenta, m.iso AS moneda_iso, 
           c.saldo, ec.nombre AS estado, c.fecha_creacion
    FROM cuenta c
    JOIN tipo_cuenta tc ON c.tipo_cuenta = tc.id
    JOIN moneda m ON c.moneda = m.id
    JOIN estado_cuenta ec ON c.estado = ec.id
    WHERE c.usuario_id = p_owner_id
    ORDER BY c.fecha_creacion DESC;

END;
$$;
