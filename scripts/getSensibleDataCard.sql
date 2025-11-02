DROP FUNCTION IF EXISTS sp_cards_get_sensible(UUID, UUID);

CREATE OR REPLACE FUNCTION sp_cards_get_sensible(
    p_usuario_id UUID,
    p_tarjeta_id UUID
) 
RETURNS TABLE (
    id UUID,
    usuario_id UUID,
    tipo VARCHAR,
    numero_enmascarado VARCHAR,
    fecha_expiracion VARCHAR,
    cvv_encrypted TEXT,
    pin_encrypted TEXT,
    moneda_iso VARCHAR,
    limite_credito DECIMAL(18,2),
    saldo_actual DECIMAL(18,2),
    fecha_creacion TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_es_admin BOOLEAN := FALSE; 
    v_owner_id UUID;
BEGIN
    -- Verificar que el usuario solicitante exista y obtener si es admin
    SELECT (LOWER(r.nombre) = 'admin')
    INTO v_es_admin
    FROM usuario u
    JOIN rol r ON u.rol = r.id
    WHERE u.id = p_usuario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario solicitante no existe';
    END IF;

    -- Verificar que la tarjeta exista y obtener su propietario
    SELECT t.usuario_id INTO v_owner_id
    FROM tarjeta t
    WHERE t.id = p_tarjeta_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tarjeta no encontrada';
    END IF;

    -- Permitir solo al propietario o admin
    IF NOT v_es_admin AND v_owner_id <> p_usuario_id THEN
        RAISE EXCEPTION 'No tiene permiso para consultar esta tarjeta.';
    END IF;

    -- Devolver los datos (cvv/pin quedan tal cual están en la tabla)
    RETURN QUERY
    SELECT
        t.id,
        t.usuario_id,
        tt.nombre AS tipo,
        t.numero_enmascarado,
        t.fecha_expiracion,
        t.cvv_hash::TEXT       AS cvv_encrypted,  -- 👈 CAST
        t.pin_hash::TEXT       AS pin_encrypted,  -- 👈 CAST
        m.iso                  AS moneda_iso,
        t.limite_credito,
        t.saldo_actual,
        t.fecha_creacion
    FROM tarjeta t
    JOIN tipo_tarjeta tt ON t.tipo = tt.id
    JOIN moneda m ON t.moneda = m.id
    WHERE t.id = p_tarjeta_id;
END;
$$;
