CREATE OR REPLACE FUNCTION sp_otp_consume_data(p_user_id UUID, p_otp VARCHAR)
RETURNS TABLE (success BOOLEAN)
AS $$
DECLARE
  v_otp_id UUID;
BEGIN
  SELECT id INTO v_otp_id
  FROM otp
  WHERE usuario_id = p_user_id
    AND fecha_consumido IS NULL
    AND fecha_expiracion > NOW()
  ORDER BY fecha_creacion DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE;
    RETURN;
  END IF;

  UPDATE otp
  SET fecha_consumido = NOW()
  WHERE id = v_otp_id
  AND proposito = p_otp;

  RETURN QUERY SELECT TRUE;
END;
$$ LANGUAGE plpgsql;
