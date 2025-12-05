-- Active: 1762051180541@@134.199.141.222@15431@fecr_damena
DROP FUNCTION IF EXISTS sp_transfer_create_internal(
    TEXT, TEXT, DECIMAL, VARCHAR, TEXT
);

CREATE OR REPLACE FUNCTION sp_transfer_create_internal(
    p_from_account_iban TEXT,
    p_to_account_iban TEXT,
    p_amount DECIMAL(18,2),
    p_currency_code VARCHAR(3),
    p_description TEXT
)
RETURNS TABLE(
    transfer_id UUID,
    receipt_number TEXT,
    status TEXT,
    error_code TEXT,
    error_message TEXT
) AS $$
DECLARE
    v_transfer_id UUID;
    v_receipt_number TEXT;
    v_from_account_id UUID;
    v_to_account_id UUID;
    v_saldo_origen DECIMAL(18,2);
    v_moneda_origen_id UUID;
    v_moneda_destino_id UUID;
    v_currency_id UUID;
    v_usuario_origen UUID;
    v_estado_origen VARCHAR;
    v_estado_destino VARCHAR;
    v_es_admin BOOLEAN;
    v_status TEXT := 'success';
    v_error_code TEXT := NULL;
    v_error_message TEXT := NULL;
BEGIN
    -- 1. VALIDACIÓN DEL IBAN DE ORIGEN
    IF p_from_account_iban IS NULL OR TRIM(p_from_account_iban) = '' THEN
        v_status := 'error';
        v_error_code := 'INVALID_FROM_IBAN';
        v_error_message := 'El IBAN de origen es requerido';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 2. VALIDACIÓN DEL IBAN DE DESTINO
    IF p_to_account_iban IS NULL OR TRIM(p_to_account_iban) = '' THEN
        v_status := 'error';
        v_error_code := 'INVALID_TO_IBAN';
        v_error_message := 'El IBAN de destino es requerido';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 3. OBTENER ID DE LA CUENTA ORIGEN POR IBAN
    SELECT id, saldo, moneda, usuario_id 
    INTO v_from_account_id, v_saldo_origen, v_moneda_origen_id, v_usuario_origen
    FROM cuenta 
    WHERE iban = p_from_account_iban;
    
    IF v_from_account_id IS NULL THEN
        v_status := 'error';
        v_error_code := 'FROM_ACCOUNT_NOT_FOUND';
        v_error_message := 'La cuenta de origen no existe';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 4. OBTENER ID DE LA CUENTA DESTINO POR IBAN
    SELECT id, moneda 
    INTO v_to_account_id, v_moneda_destino_id
    FROM cuenta 
    WHERE iban = p_to_account_iban;
    
    IF v_to_account_id IS NULL THEN
        v_status := 'error';
        v_error_code := 'TO_ACCOUNT_NOT_FOUND';
        v_error_message := 'La cuenta de destino no existe';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 5. OBTENER ID DE LA MONEDA POR CÓDIGO (CRC/USD)
    SELECT id INTO v_currency_id
    FROM moneda 
    WHERE codigo_iso = UPPER(p_currency_code);
    
    IF v_currency_id IS NULL THEN
        v_status := 'error';
        v_error_code := 'INVALID_CURRENCY';
        v_error_message := 'La moneda especificada no es válida';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    
    -- 7. VALIDAR ESTADOS DE LAS CUENTAS
    -- 7.1 Obtener estado de cuenta origen
    SELECT ec.nombre INTO v_estado_origen
    FROM cuenta c
    INNER JOIN estado_cuenta ec ON c.estado = ec.id
    WHERE c.id = v_from_account_id;
    
    -- 7.2 Obtener estado de cuenta destino
    SELECT ec.nombre INTO v_estado_destino
    FROM cuenta c
    INNER JOIN estado_cuenta ec ON c.estado = ec.id
    WHERE c.id = v_to_account_id;
    
    -- 7.3 Validar que ambas cuentas estén activas
    IF LOWER(v_estado_origen) NOT IN ('activa', 'habilitada', 'disponible', 'active') THEN
        v_status := 'error';
        v_error_code := 'FROM_ACCOUNT_INACTIVE';
        v_error_message := 'La cuenta de origen no está activa';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    IF LOWER(v_estado_destino) NOT IN ('activa', 'habilitada', 'disponible', 'active') THEN
        v_status := 'error';
        v_error_code := 'TO_ACCOUNT_INACTIVE';
        v_error_message := 'La cuenta de destino no está activa';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 8. VALIDAR QUE NO SEA LA MISMA CUENTA
    IF v_from_account_id = v_to_account_id THEN
        v_status := 'error';
        v_error_code := 'SAME_ACCOUNT';
        v_error_message := 'No puedes transferir a la misma cuenta';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 9. VALIDAR SALDO
    IF v_saldo_origen < p_amount THEN
        v_status := 'error';
        v_error_code := 'INSUFFICIENT_FUNDS';
        v_error_message := 'Fondos insuficientes en la cuenta de origen';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 10. VALIDAR MONEDAS
    IF v_moneda_origen_id != v_currency_id THEN
        v_status := 'error';
        v_error_code := 'FROM_CURRENCY_MISMATCH';
        v_error_message := 'La moneda de la cuenta origen no coincide';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    IF v_moneda_destino_id != v_currency_id THEN
        v_status := 'error';
        v_error_code := 'TO_CURRENCY_MISMATCH';
        v_error_message := 'La moneda de la cuenta destino no coincide';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
        RETURN;
    END IF;
    
    -- 11. VALIDAR MONTO POSITIVO
    IF p_amount <= 0 THEN
        v_status := 'error';
        v_error_code := 'INVALID_AMOUNT';
        v_error_message := 'El monto debe ser mayor a cero';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status, v_error_code, v_error_message;
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
            descripcion,
            fecha_transferencia
        ) VALUES (
            v_from_account_id,
            v_to_account_id,
            v_currency_id,
            p_amount,
            p_description,
            NOW()
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
            v_from_account_id,
            (SELECT id FROM tipo_movimiento_cuenta WHERE nombre = 'Debito'),
            COALESCE(p_description, 'Transferencia a cuenta: ' || p_to_account_iban),
            v_currency_id,
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
            v_to_account_id,
            (SELECT id FROM tipo_movimiento_cuenta WHERE nombre = 'Credito'),
            COALESCE(p_description, 'Transferencia de cuenta: ' || p_from_account_iban),
            v_currency_id,
            p_amount,
            NOW()
        );
        
        -- Actualizar saldos
        UPDATE cuenta SET 
            saldo = saldo - p_amount, 
            fecha_actualizacion = NOW()
        WHERE id = v_from_account_id;
        
        UPDATE cuenta SET 
            saldo = saldo + p_amount, 
            fecha_actualizacion = NOW()
        WHERE id = v_to_account_id;
        
        -- Retornar resultados exitosos
        RETURN QUERY SELECT 
            v_transfer_id, 
            v_receipt_number, 
            v_status,
            v_error_code,
            v_error_message;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_status := 'error';
            v_error_code := 'INTERNAL_ERROR';
            v_error_message := 'Error interno del servidor: ' || SQLERRM;
            RETURN QUERY SELECT 
                NULL::UUID, 
                NULL::TEXT, 
                v_status,
                v_error_code,
                v_error_message;
    END;
    
END;
$$ LANGUAGE plpgsql;