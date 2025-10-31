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
    v_status TEXT := 'success';
BEGIN
    -- Verificar saldo y moneda de la cuenta origen
    SELECT saldo, moneda INTO v_saldo_origen, v_moneda_origen
    FROM cuenta 
    WHERE id = p_from_account_id;
    
    -- Verificar moneda de la cuenta destino
    SELECT moneda INTO v_moneda_destino
    FROM cuenta 
    WHERE id = p_to_account_id;
    
    -- Validaciones
    IF v_saldo_origen < p_amount THEN
        v_status := 'insufficient_funds';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    IF v_moneda_origen != p_currency OR v_moneda_destino != p_currency THEN
        v_status := 'currency_mismatch';
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, v_status;
        RETURN;
    END IF;
    
    -- Generar número de recibo
    v_receipt_number := 'TRF-' || to_char(NOW(), 'YYYYMMDD-HH24MISS');
    
    -- Iniciar transacción
    BEGIN
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
            monto
        ) VALUES (
            p_from_account_id,
            (SELECT id FROM tipo_movimiento_cuenta WHERE nombre = 'Debito'),
            'Transferencia a cuenta: ' || (SELECT iban FROM cuenta WHERE id = p_to_account_id),
            p_currency,
            -p_amount
        );
        
        -- Registrar movimiento de crédito en cuenta destino
        INSERT INTO movimiento_cuenta (
            cuenta_id,
            tipo,
            descripcion,
            moneda,
            monto
        ) VALUES (
            p_to_account_id,
            (SELECT id FROM tipo_movimiento_cuenta WHERE nombre = 'Credito'),
            'Transferencia de cuenta: ' || (SELECT iban FROM cuenta WHERE id = p_from_account_id),
            p_currency,
            p_amount
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