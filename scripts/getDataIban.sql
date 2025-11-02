DROP FUNCTION IF EXISTS sp_bank_validate_account(VARCHAR);

CREATE OR REPLACE FUNCTION sp_bank_validate_account(
    p_iban VARCHAR
)
RETURNS TABLE (
    nombre VARCHAR,
    apellido VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que el IBAN exista en la tabla cuenta
    IF NOT EXISTS (SELECT 1 FROM cuenta WHERE iban = p_iban) THEN
        RAISE EXCEPTION 'La cuenta con IBAN "%" no existe.', p_iban;
    END IF;

    -- Retornar los datos del titular
    RETURN QUERY
    SELECT u.nombre, u.apellido
    FROM cuenta c
    JOIN usuario u ON c.usuario_id = u.id
    WHERE c.iban = p_iban
    LIMIT 1;

END;
$$;
