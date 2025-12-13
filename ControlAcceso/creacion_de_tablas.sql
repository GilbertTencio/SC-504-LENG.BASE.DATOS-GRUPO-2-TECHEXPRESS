-- =======================================================================================
-- 4.2. CREACIÓN DE TABLAS - TECHXPRESS
-- Scripts para crear tablas, secuencias y constraints en cada esquema.
-- Ejecutar en las conexiones respectivas después de crear usuarios.
-- =======================================================================================

-- En BASE_TABLAS
-- Conectar como base_tablas
CREATE TABLE clientes (
  idCliente NUMBER(10) CONSTRAINT pk_clientes PRIMARY KEY,
  nombre VARCHAR2(100) NOT NULL,
  telefono VARCHAR2(20),
  email VARCHAR2(100),
  direccion VARCHAR2(200)
);

CREATE TABLE tecnicos (
  idTecnico NUMBER(10) CONSTRAINT pk_tecnicos PRIMARY KEY,
  nombre VARCHAR2(100) NOT NULL,
  telefono VARCHAR2(20),
  email VARCHAR2(100)
);

CREATE TABLE servicios (
  idServicio NUMBER(10) CONSTRAINT pk_servicios PRIMARY KEY,
  descripcion VARCHAR2(200) NOT NULL,
  costo NUMBER(10,2) NOT NULL
);

-- En OPS_TABLAS
-- Conectar como ops_tablas
CREATE SEQUENCE seq_ordenestrabajo START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE TABLE equipos (
  idEquipo NUMBER(10) CONSTRAINT pk_equipos PRIMARY KEY,
  idCliente NUMBER(10) NOT NULL,
  tipo_equipo VARCHAR2(50) NOT NULL,
  marca VARCHAR2(50),
  modelo VARCHAR2(50),
  numero_serie VARCHAR2(100)
);

CREATE TABLE ordenestrabajo (
  idOrden NUMBER(10) CONSTRAINT pk_ordenestrabajo PRIMARY KEY,
  idEquipo NUMBER(10) NOT NULL,
  idTecnico NUMBER(10) NOT NULL,
  fecha_ingreso DATE NOT NULL,
  fecha_entrega DATE,
  estado VARCHAR2(20) NOT NULL,
  observaciones CLOB,
  idFactura NUMBER(10) NOT NULL
);

ALTER TABLE ordenestrabajo ADD CONSTRAINT ordenes_estado_chk
  CHECK (estado IN ('ABIERTA','EN_PROCESO','CERRADA','CANCELADA'));

CREATE TABLE ordenes_servicio (
  idOrden NUMBER(10) NOT NULL,
  idServicio NUMBER(10) NOT NULL,
  cantidad NUMBER(10) NOT NULL,
  CONSTRAINT ordenes_servicio_pk PRIMARY KEY (idOrden, idServicio)
);

-- En FACT_TABLAS
-- Conectar como fact_tablas
CREATE SEQUENCE seq_facturas START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE TABLE facturas (
  id_factura NUMBER(10) CONSTRAINT pk_facturas PRIMARY KEY,
  fecha_factura DATE NOT NULL,
  total NUMBER(10,2) NOT NULL,
  metodo_pago VARCHAR2(20) NOT NULL,
  clientes_id_cliente NUMBER(10) NOT NULL
);

ALTER TABLE facturas ADD CONSTRAINT facturas_metodo_pago_chk
  CHECK (metodo_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA','PENDIENTE'));

-- Otorgar REFERENCES después de crear tablas (ejecutar en SYSTEM o conexiones respectivas)
-- GRANT REFERENCES ON BASE_TABLAS.clientes TO ops_tablas;
-- GRANT REFERENCES ON BASE_TABLAS.tecnicos TO ops_tablas;
-- GRANT REFERENCES ON BASE_TABLAS.servicios TO ops_tablas;
-- GRANT REFERENCES ON OPS_TABLAS.ordenestrabajo TO fact_tablas;
-- GRANT SELECT, REFERENCES ON BASE_TABLAS.clientes TO FACT_TABLAS;

-- Fin del script