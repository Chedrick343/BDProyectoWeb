

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


DROP TABLE IF EXISTS api_key CASCADE;
DROP TABLE IF EXISTS otp CASCADE;
DROP TABLE IF EXISTS transferencia CASCADE;
DROP TABLE IF EXISTS movimiento_tarjeta CASCADE;
DROP TABLE IF EXISTS tarjeta CASCADE;
DROP TABLE IF EXISTS movimiento_cuenta CASCADE;
DROP TABLE IF EXISTS cuenta CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

DROP TABLE IF EXISTS estado_cuenta CASCADE;
DROP TABLE IF EXISTS moneda CASCADE;
DROP TABLE IF EXISTS tipo_movimiento_tarjeta CASCADE;
DROP TABLE IF EXISTS tipo_movimiento_cuenta CASCADE;
DROP TABLE IF EXISTS tipo_tarjeta CASCADE;
DROP TABLE IF EXISTS tipo_cuenta CASCADE;
DROP TABLE IF EXISTS tipo_identificacion CASCADE;
DROP TABLE IF EXISTS rol CASCADE;

-- ===========================================
-- TABLAS BÁSICAS DE CONFIGURACIÓN
-- ===========================================

CREATE TABLE rol (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_identificacion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_cuenta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_tarjeta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_movimiento_cuenta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE tipo_movimiento_tarjeta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE moneda (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    iso VARCHAR(10) NOT NULL
);

CREATE TABLE estado_cuenta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

-- ===========================================
-- TABLA USUARIO
-- ===========================================

CREATE TABLE usuario (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tipo_identificacion UUID NOT NULL REFERENCES tipo_identificacion(id),
    identificacion VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    usuario VARCHAR(50) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    rol UUID NOT NULL REFERENCES rol(id),
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP DEFAULT NOW()
);



CREATE TABLE cuenta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id),
    iban VARCHAR(34) NOT NULL UNIQUE,
    alias VARCHAR(50),
    tipo_cuenta UUID NOT NULL REFERENCES tipo_cuenta(id),
    moneda UUID NOT NULL REFERENCES moneda(id),
    saldo DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    estado UUID NOT NULL REFERENCES estado_cuenta(id),
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP DEFAULT NOW()
);

CREATE TABLE movimiento_cuenta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_id UUID NOT NULL REFERENCES cuenta(id),
    fecha TIMESTAMP DEFAULT NOW(),
    tipo UUID NOT NULL REFERENCES tipo_movimiento_cuenta(id),
    descripcion TEXT,
    moneda UUID NOT NULL REFERENCES moneda(id),
    monto DECIMAL(18,2) NOT NULL
);


CREATE TABLE tarjeta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id),
    tipo UUID NOT NULL REFERENCES tipo_tarjeta(id),
    numero_enmascarado VARCHAR(25) NOT NULL,
    fecha_expiracion VARCHAR(5) NOT NULL,  -- formato MM/YY
    cvv_hash VARCHAR(255) NOT NULL,
    pin_hash VARCHAR(255) NOT NULL,
    moneda UUID NOT NULL REFERENCES moneda(id),
    limite_credito DECIMAL(18,2) NOT NULL,
    saldo_actual DECIMAL(18,2) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP DEFAULT NOW()
);

CREATE TABLE movimiento_tarjeta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tarjeta_id UUID NOT NULL REFERENCES tarjeta(id),
    fecha TIMESTAMP DEFAULT NOW(),
    tipo UUID NOT NULL REFERENCES tipo_movimiento_tarjeta(id),
    descripcion TEXT,
    moneda UUID NOT NULL REFERENCES moneda(id),
    monto DECIMAL(18,2) NOT NULL
);



CREATE TABLE transferencia (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_origen UUID NOT NULL REFERENCES cuenta(id),
    cuenta_destino UUID NOT NULL REFERENCES cuenta(id),
    moneda UUID NOT NULL REFERENCES moneda(id),
    monto DECIMAL(18,2) NOT NULL,
    descripcion TEXT,
    fecha_transferencia TIMESTAMP DEFAULT NOW()
);

CREATE TABLE otp (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuario(id),
    codigo_hash VARCHAR(255) NOT NULL,
    proposito VARCHAR(50) NOT NULL CHECK (proposito IN ('password_reset', 'card_details')),
    fecha_expiracion TIMESTAMP NOT NULL,
    fecha_consumido TIMESTAMP NULL,
    fecha_creacion TIMESTAMP DEFAULT NOW()
);



CREATE TABLE api_key (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clave_hash VARCHAR(255) NOT NULL,
    etiqueta VARCHAR(100),
    activa BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT NOW()
);
