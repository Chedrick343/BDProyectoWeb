-- Active: 1761282992477@@134.199.141.222@15431@fecr_damena
--CREACIÓN DE TABLAS JIMENA MENDEZ Y CHEDRICK UZAGA
--PARA TENER LAS TABLAS COMPLETAS DE LA BASE DE DATOS EJECUTAR ESTE SCRIPT
CREATE TABLE tipo_identificacion (
    id_identificacion SERIAL PRIMARY KEY,
    nombre_identificacion VARCHAR(50) NOT NULL
);

CREATE TABLE persona (
    id_persona SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    primer_apellido VARCHAR(100) NOT NULL,
    segundo_apellido VARCHAR(100),
    numero_identificacion VARCHAR(50) NOT NULL UNIQUE,
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

CREATE TABLE cuenta (
    numero_cuenta VARCHAR(30) PRIMARY KEY,
    alias VARCHAR(50),
    tipo_cuenta VARCHAR(20) NOT NULL,
    moneda VARCHAR(10) NOT NULL,
    saldo_disponible DECIMAL(15,2) NOT NULL,
    id_persona INT NOT NULL REFERENCES persona(id_persona)
);

CREATE TABLE movimientos_cuenta (
    id SERIAL PRIMARY KEY,
    numero_cuenta VARCHAR(30) NOT NULL REFERENCES cuenta(numero_cuenta),
    fecha_movimiento TIMESTAMP NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    descripcion VARCHAR(255),
    moneda VARCHAR(10),
    saldo_movimiento DECIMAL(15,2) NOT NULL
);

CREATE TABLE tipo_tarjeta (
    id_tipo SERIAL PRIMARY KEY,
    nombre_tipo VARCHAR(50) NOT NULL
);

CREATE TABLE tarjeta (
    numero_tarjeta VARCHAR(30) PRIMARY KEY,
    id_tipo INT NOT NULL REFERENCES tipo_tarjeta(id_tipo),
    expiracion DATE NOT NULL,
    pin VARCHAR(10) NOT NULL,
    cvv VARCHAR(10) NOT NULL,
    moneda VARCHAR(10) NOT NULL,
    limite DECIMAL(15,2) NOT NULL,
    saldo DECIMAL(15,2) NOT NULL,
    id_persona INT NOT NULL REFERENCES persona(id_persona)
);


CREATE TABLE movimientos_tarjeta (
    id SERIAL PRIMARY KEY,
    id_tarjeta VARCHAR(30) NOT NULL REFERENCES tarjeta(numero_tarjeta),
    fecha_movimiento TIMESTAMP NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    descripcion VARCHAR(255),
    moneda VARCHAR(10),
    saldo_movimiento DECIMAL(15,2) NOT NULL
);


CREATE TABLE transferencia (
    id SERIAL PRIMARY KEY,
    cuenta_origen VARCHAR(30) NOT NULL REFERENCES cuenta(numero_cuenta),
    cuenta_destino VARCHAR(30) NOT NULL REFERENCES cuenta(numero_cuenta),
    moneda VARCHAR(10) NOT NULL,
    monto DECIMAL(15,2) NOT NULL,
    descripcion VARCHAR(255),
    fecha_transferencia TIMESTAMP NOT NULL
);