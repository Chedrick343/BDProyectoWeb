CREATE OR REPLACE FUNCTION sp_bank_validate_account(
    p_iban VARCHAR(34)
)
RETURNS TABLE(
    exists_flag BOOLEAN,
    owner_name TEXT,
    owner_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TRUE AS exists_flag,
        (u.nombre || ' ' || u.apellido)::TEXT AS owner_name,
        u.id AS owner_id
    FROM cuenta c
    INNER JOIN usuario u ON c.usuario_id = u.id
    WHERE c.iban = p_iban;
    
    -- Si no se encontró ninguna cuenta, retornar false
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::TEXT, NULL::UUID;
    END IF;
    
END;
$$ LANGUAGE plpgsql;