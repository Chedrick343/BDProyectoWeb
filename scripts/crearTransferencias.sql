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
    v_status TEXT := 'success';
BEGIN
    -- 1. VERIFICAR QUE LA CUENTA ORIGEN EXISTA
    SELECT saldo, moneda, usuario_id 
    INTO v_saldo_origen, v_moneda_origen, v_usuario_origen
    FROM cuenta 
    WHERE id = p_from_account_id;
    
    IF NOT FOUND THEN
        v_status := 'account_not_found';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 2. VERIFICAR QUE LA CUENTA DESTINO EXISTA
    SELECT moneda INTO v_moneda_destino
    FROM cuenta 
    WHERE id = p_to_account_id;
    
    IF NOT FOUND THEN
        v_status := 'account_not_found';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 3. VALIDAR PROPIEDAD: usuario debe ser dueño o administrador
    -- 3.1 Verificar si es administrador
    SELECT EXISTS(
        SELECT 1 FROM usuario u
        INNER JOIN rol r ON u.rol = r.id
        WHERE u.id = p_user_id 
        AND LOWER(r.nombre) = 'administrador'
    ) INTO v_es_admin;
    
    -- 3.2 Validar propiedad (si no es admin, debe ser dueño)
    IF NOT v_es_admin AND v_usuario_origen != p_user_id THEN
        v_status := 'unauthorized';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 4. VALIDAR ESTADOS DE LAS CUENTAS
    -- 4.1 Obtener estado de cuenta origen
    SELECT ec.nombre INTO v_estado_origen
    FROM cuenta c
    INNER JOIN estado_cuenta ec ON c.estado = ec.id
    WHERE c.id = p_from_account_id;
    
    -- 4.2 Obtener estado de cuenta destino
    SELECT ec.nombre INTO v_estado_destino
    FROM cuenta c
    INNER JOIN estado_cuenta ec ON c.estado = ec.id
    WHERE c.id = p_to_account_id;
    
    -- 4.3 Validar que ambas cuentas estén activas
    IF LOWER(v_estado_origen) NOT IN ('activa', 'habilitada', 'disponible', 'active') THEN
        v_status := 'account_inactive';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    IF LOWER(v_estado_destino) NOT IN ('activa', 'habilitada', 'disponible', 'active') THEN
        v_status := 'account_inactive';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 5. VALIDAR QUE NO SEA LA MISMA CUENTA
    IF p_from_account_id = p_to_account_id THEN
        v_status := 'same_account';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 6. VALIDAR SALDO (ya existía)
    IF v_saldo_origen < p_amount THEN
        v_status := 'insufficient_funds';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 7. VALIDAR QUE LA MONEDA SOLICITADA EXISTA
    IF NOT EXISTS (SELECT 1 FROM moneda WHERE id = p_currency) THEN
        v_status := 'invalid_currency';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 8. VALIDAR MONEDAS (ya existía)
    IF v_moneda_origen != p_currency OR v_moneda_destino != p_currency THEN
        v_status := 'currency_mismatch';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- 9. VALIDAR MONTO POSITIVO
    IF p_amount <= 0 THEN
        v_status := 'invalid_amount';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- TODAS LAS VALIDACIONES PASARON → PROCEDER CON TRANSFERENCIA
    BEGIN
        -- Generar número de recibo
        v_receipt_number := 'TRF-' || to_char(NOW(), 'YYYYMMDD-HH24MISS');
        
        -- Insertar transferencia
        INSERT INTO transferencia (
            cuenta_origen,
            cuenta_destino,
            moneda,
            monto,
            descripcion
        ) VALUES (
            p_from_account_id,
            p_to_account_id,
            p_currency,
            p_amount,
            p_description
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
        UPDATE cuenta SET saldo = saldo - p_amount, fecha_actualizacion = NOW()
        WHERE id = p_from_account_id;
        
        UPDATE cuenta SET saldo = saldo + p_amount, fecha_actualizacion = NOW()
        WHERE id = p_to_account_id;
        
        -- Retornar resultados exitosos
        RETURN QUERY SELECT v_transfer_id, v_receipt_number, v_status;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_status := 'error';
            RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
    END;
    
END;
$$ LANGUAGE plpgsql;