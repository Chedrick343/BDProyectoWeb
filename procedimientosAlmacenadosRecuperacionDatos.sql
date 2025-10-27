CREATE OR REPLACE PROCEDURE crear_usuario(
    p_nombre VARCHAR,
    p_primer_apellido VARCHAR,
    p_segundo_apellido VARCHAR,
    p_numero_identificacion VARCHAR,
    p_id_identificacion INT,
    p_nombre_usuario VARCHAR,
    p_correo_electronico VARCHAR,
    p_contrasena VARCHAR,
    p_numero_telefono VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_persona_id INT;
BEGIN
    BEGIN
        INSERT INTO persona (
            nombre,
            primer_apellido,
            segundo_apellido,
            numero_identificacion,
            id_identificacion,
            numero_telefono
        )
        VALUES (
            p_nombre,
            p_primer_apellido,
            p_segundo_apellido,
            p_numero_identificacion,
            p_id_identificacion,
            p_numero_telefono
        )
        RETURNING id_persona INTO v_persona_id;

        INSERT INTO usuario (
            nombre_usuario,
            correo_electronico,
            contrasena,
            id_persona
        )
        VALUES (
            p_nombre_usuario,
            lower(p_correo_electronico),
            crypt(p_contrasena, gen_salt('bf')),
            v_persona_id
        );

        RAISE NOTICE 'Usuario creado exitosamente (persona id = %, usuario id generado automáticamente)', v_persona_id;

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'Error: el número de identificación o el nombre de usuario ya existen.';
        WHEN others THEN
            RAISE NOTICE 'Error inesperado al crear el usuario: %', SQLERRM;
    END;
END;
$$;
