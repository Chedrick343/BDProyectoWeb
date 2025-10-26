CREATE TABLE tipo_identificacion (
    id_identificacion SERIAL PRIMARY KEY,
    nombre_identificacion VARCHAR(50) NOT NULL
);

CREATE TABLE persona (
    id_persona SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    primer_apellido VARCHAR(100) NOT NULL,
    segundo_apellido VARCHAR(100),
    numero_identificacion VARCHAR(50) NOT NULL,
    id_identificacion INT NOT NULL REFERENCES tipo_identificacion(id_identificacion),
    numero_telefono VARCHAR(20)
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL,
    correo_electronico VARCHAR(150) NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    id_persona INT NOT NULL REFERENCES persona(id_persona)
);