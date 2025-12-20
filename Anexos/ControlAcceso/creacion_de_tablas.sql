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


--Inserts de datos
-- =======================================================================================
-- INSERTS ALEATORIOS PARA TABLAS PRINCIPALES - TECHXPRESS
-- Archivo: inserts_aleatorios.sql
-- Descripción: 50 inserts de datos aleatorios para pruebas.
-- Distribución: 10 clientes, 5 técnicos, 5 servicios, 10 equipos, 10 órdenes, 5 órdenes_servicio, 5 facturas.
-- Ejecutar en el orden de las secciones para mantener integridad referencial.
-- =======================================================================================

-- BASE_TABLAS.clientes (10 inserts)
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (1, 'Ana López', '555-1001', 'ana.lopez@email.com', 'Av. Principal 123');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (2, 'Carlos Ramírez', '555-1002', 'carlos.ramirez@email.com', 'Calle Secundaria 456');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (3, 'María González', '555-1003', 'maria.gonzalez@email.com', 'Plaza Central 789');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (4, 'José Martínez', '555-1004', 'jose.martinez@email.com', 'Boulevard Norte 101');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (5, 'Laura Sánchez', '555-1005', 'laura.sanchez@email.com', 'Ruta Sur 202');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (6, 'Pedro Díaz', '555-1006', 'pedro.diaz@email.com', 'Camino Este 303');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (7, 'Sofia Torres', '555-1007', 'sofia.torres@email.com', 'Vía Oeste 404');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (8, 'Miguel Ruiz', '555-1008', 'miguel.ruiz@email.com', 'Paseo Alto 505');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (9, 'Elena Vargas', '555-1009', 'elena.vargas@email.com', 'Sendero Bajo 606');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (10, 'Roberto Castro', '555-1010', 'roberto.castro@email.com', 'Avenida Baja 707');

-- BASE_TABLAS.tecnicos (5 inserts)
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (1, 'Técnico Alfa', '555-2001', 'tecnico.alfa@email.com');
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (2, 'Técnico Beta', '555-2002', 'tecnico.beta@email.com');
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (3, 'Técnico Gamma', '555-2003', 'tecnico.gamma@email.com');
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (4, 'Técnico Delta', '555-2004', 'tecnico.delta@email.com');
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (5, 'Técnico Epsilon', '555-2005', 'tecnico.epsilon@email.com');

-- BASE_TABLAS.servicios (5 inserts)
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (1, 'Reparación de pantalla', 450.00);
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (2, 'Cambio de batería', 180.00);
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (3, 'Limpieza interna', 120.00);
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (4, 'Actualización de software', 300.00);
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (5, 'Reemplazo de teclado', 250.00);

-- OPS_TABLAS.equipos (10 inserts, referenciando clientes 1-10)
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (1, 1, 'Laptop', 'Dell', 'Inspiron 15', 'SN1001');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (2, 2, 'Teléfono', 'Samsung', 'Galaxy A52', 'SN1002');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (3, 3, 'Tablet', 'Apple', 'iPad Air', 'SN1003');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (4, 4, 'Laptop', 'HP', 'EliteBook', 'SN1004');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (5, 5, 'Teléfono', 'Xiaomi', 'Redmi Note 10', 'SN1005');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (6, 6, 'Desktop', 'Lenovo', 'ThinkCentre', 'SN1006');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (7, 7, 'Laptop', 'Asus', 'ZenBook', 'SN1007');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (8, 8, 'Teléfono', 'Huawei', 'P40 Lite', 'SN1008');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (9, 9, 'Tablet', 'Samsung', 'Galaxy Tab S7', 'SN1009');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (10, 10, 'Laptop', 'Acer', 'Aspire 5', 'SN1010');

-- FACT_TABLAS.facturas (5 inserts, referenciando clientes 1-5)
INSERT INTO FACT_TABLAS.facturas (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente) VALUES (1, SYSDATE-10, 0.00, 'PENDIENTE', 1);
INSERT INTO FACT_TABLAS.facturas (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente) VALUES (2, SYSDATE-9, 0.00, 'PENDIENTE', 2);
INSERT INTO FACT_TABLAS.facturas (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente) VALUES (3, SYSDATE-8, 0.00, 'PENDIENTE', 3);
INSERT INTO FACT_TABLAS.facturas (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente) VALUES (4, SYSDATE-7, 0.00, 'PENDIENTE', 4);
INSERT INTO FACT_TABLAS.facturas (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente) VALUES (5, SYSDATE-6, 0.00, 'PENDIENTE', 5);

-- OPS_TABLAS.ordenestrabajo (10 inserts, referenciando equipos 1-10, técnicos 1-5, facturas 1-5)
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (1, 1, 1, SYSDATE-5, SYSDATE-2, 'CERRADA', 'Reparación completada', 1);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (2, 2, 2, SYSDATE-4, SYSDATE-1, 'EN_PROCESO', 'En revisión', 2);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (3, 3, 3, SYSDATE-3, SYSDATE, 'ABIERTA', NULL, 3);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (4, 4, 4, SYSDATE-2, SYSDATE+1, 'ABIERTA', NULL, 4);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (5, 5, 5, SYSDATE-1, SYSDATE+2, 'EN_PROCESO', 'Esperando partes', 5);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (6, 6, 1, SYSDATE, SYSDATE+3, 'ABIERTA', NULL, 1);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (7, 7, 2, SYSDATE+1, SYSDATE+4, 'CERRADA', 'Entregado', 2);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (8, 8, 3, SYSDATE+2, SYSDATE+5, 'EN_PROCESO', NULL, 3);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (9, 9, 4, SYSDATE+3, SYSDATE+6, 'ABIERTA', NULL, 4);
INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura) VALUES (10, 10, 5, SYSDATE+4, SYSDATE+7, 'CANCELADA', 'Cliente canceló', 5);

-- OPS_TABLAS.ordenes_servicio (5 inserts, referenciando órdenes 1-5 y servicios 1-5)
INSERT INTO OPS_TABLAS.ordenes_servicio (idOrden, idServicio, cantidad) VALUES (1, 1, 1);
INSERT INTO OPS_TABLAS.ordenes_servicio (idOrden, idServicio, cantidad) VALUES (2, 2, 2);
INSERT INTO OPS_TABLAS.ordenes_servicio (idOrden, idServicio, cantidad) VALUES (3, 3, 1);
INSERT INTO OPS_TABLAS.ordenes_servicio (idOrden, idServicio, cantidad) VALUES (4, 4, 1);
INSERT INTO OPS_TABLAS.ordenes_servicio (idOrden, idServicio, cantidad) VALUES (5, 5, 3);

COMMIT;

-- Fin del archivo
-- =======================================================================================