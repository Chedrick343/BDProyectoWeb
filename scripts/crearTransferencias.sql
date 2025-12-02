

DROP FUNCTION IF EXISTS sp_transfer_create_internal(
    UUID, UUID, DECIMAL, UUID, TEXT, UUID
);

CREATE OR REPLACE FUNCTION sp_transfer_create_internal(
    p_from_account_id UUID,
    p_to_account_id UUID,
    p_amount DECIMAL(18,2),
    p_currency UUID,
    p_description TEXT,
    p_user_id UUID
)
RETURNS TABLE(
    transfer_id UUID,
    receipt_number TEXT,
    status TEXT
) AS $$
DECLARE
    v_transfer_id UUID;
    v_receipt_number TEXT;
    v_saldo_origen DECIMAL(18,2);
    v_moneda_origen UUID;
    v_moneda_destino UUID;
    v_usuario_origen UUID;
    v_estado_origen VARCHAR;
    v_estado_destino VARCHAR;
    v_es_admin BOOLEAN;
    v_moneda_iso_origin VARCHAR;
    v_moneda_iso_destino VARCHAR;
    v_moneda_iso_requested VARCHAR;
BEGIN
    -- Iniciar con valores por defecto
    transfer_id := NULL;
    receipt_number := NULL;
    status := 'error';

    -- Verificar si el usuario es administrador
    SELECT EXISTS(
        SELECT 1 FROM usuario u
        INNER JOIN rol r ON u.rol = r.id
        WHERE u.id = p_user_id 
        AND LOWER(r.nombre) = 'administrador'
    ) INTO v_es_admin;

    -- VERIFICACIÓN 1: Cuenta origen existe y obtener datos
    SELECT 
        c.saldo, 
        c.moneda,
        c.usuario_id,
        ec.nombre as estado_nombre,
        m.iso as moneda_iso
    INTO 
        v_saldo_origen, 
        v_moneda_origen,
        v_usuario_origen,
        v_estado_origen,
        v_moneda_iso_origin
    FROM cuenta c
    INNER JOIN estado_cuenta ec ON c.estado = ec.id
    INNER JOIN moneda m ON c.moneda = m.id
    WHERE c.id = p_from_account_id;

    IF NOT FOUND THEN
        status := 'account_not_found';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 2: Propiedad de la cuenta origen
    IF NOT v_es_admin AND v_usuario_origen != p_user_id THEN
        status := 'unauthorized';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 3: Estado de cuenta origen (FLEXIBLE)
    IF LOWER(v_estado_origen) NOT IN ('activa', 'habilitada', 'disponible', 'active') THEN
        status := 'account_inactive';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 4: Cuenta destino existe
    SELECT 
        c.moneda,
        ec.nombre as estado_nombre,
        m.iso as moneda_iso
    INTO 
        v_moneda_destino,
        v_estado_destino,
        v_moneda_iso_destino
    FROM cuenta c
    INNER JOIN estado_cuenta ec ON c.estado = ec.id
    INNER JOIN moneda m ON c.moneda = m.id
    WHERE c.id = p_to_account_id;

    IF NOT FOUND THEN
        status := 'account_not_found';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 5: Estado de cuenta destino (FLEXIBLE)
    IF LOWER(v_estado_destino) NOT IN ('activa', 'habilitada', 'disponible', 'active') THEN
        status := 'account_inactive';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 6: No transferir a la misma cuenta
    IF p_from_account_id = p_to_account_id THEN
        status := 'same_account';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 7: Saldo suficiente
    IF v_saldo_origen < p_amount THEN
        status := 'insufficient_funds';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 8: Obtener moneda solicitada
    SELECT iso INTO v_moneda_iso_requested
    FROM moneda 
    WHERE id = p_currency;

    IF NOT FOUND THEN
        status := 'invalid_currency';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 9: Coincidencia de monedas
    IF v_moneda_iso_origin != v_moneda_iso_requested OR 
       v_moneda_iso_destino != v_moneda_iso_requested THEN
        status := 'currency_mismatch';
        RETURN NEXT;
        RETURN;
    END IF;

    -- VERIFICACIÓN 10: Monto positivo
    IF p_amount <= 0 THEN
        status := 'invalid_amount';
        RETURN NEXT;
        RETURN;
    END IF;

    -- TODAS LAS VALIDACIONES PASARON → PROCEDER CON TRANSFERENCIA
    BEGIN
        -- Generar número de recibo
        v_receipt_number := 'TRF-' || to_char(NOW(), 'YYYYMMDD-HH24MISS') || 
                           '-' || substr(p_from_account_id::text, 1, 8);
        
        -- Insertar transferencia
        INSERT INTO transferencia (
            cuenta_origen,
            cuenta_destino,
            moneda,
            monto,
            descripcion,
            numero_recibo,
            estado,
            usuario_id
        ) VALUES (
            p_from_account_id,
            p_to_account_id,
            p_currency,
            p_amount,
            p_description,
            v_receipt_number,
            'completada',
            p_user_id
        ) RETURNING id INTO v_transfer_id;
        
        -- Registrar movimiento de débito en cuenta origen
        INSERT INTO movimiento_cuenta (
            cuenta_id,
            tipo,
            descripcion,
            moneda,
            monto,
            fecha
        ) VALUES (
            p_from_account_id,
            (SELECT id FROM tipo_movimiento_cuenta WHERE nombre = 'Debito'),
            'Transferencia a cuenta: ' || (SELECT iban FROM cuenta WHERE id = p_to_account_id),
            p_currency,
            -p_amount,
            NOW()
        );
        
        -- Registrar movimiento de crédito en cuenta destino
        INSERT INTO movimiento_cuenta (
            cuenta_id,
            tipo,
            descripcion,
            moneda,
            monto,
            fecha
        ) VALUES (
            p_to_account_id,
            (SELECT id FROM tipo_movimiento_cuenta WHERE nombre = 'Credito'),
            'Transferencia de cuenta: ' || (SELECT iban FROM cuenta WHERE id = p_from_account_id),
            p_currency,
            p_amount,
            NOW()
        );
        
        -- Actualizar saldos
        UPDATE cuenta 
        SET saldo = saldo - p_amount, 
            fecha_actualizacion = NOW()
        WHERE id = p_from_account_id;
        
        UPDATE cuenta 
        SET saldo = saldo + p_amount, 
            fecha_actualizacion = NOW()
        WHERE id = p_to_account_id;
        
        -- Retornar éxito
        transfer_id := v_transfer_id;
        receipt_number := v_receipt_number;
        status := 'success';
        
        RETURN NEXT;
        RETURN;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- En caso de error en la transacción
            status := 'error';
            RETURN NEXT;
            RETURN;
    END;
    
END;
$$ LANGUAGE plpgsql;