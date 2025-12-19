-- =======================================================================================
-- ESCENARIO DE PRUEBAS - TECHXPRESS
-- Archivo: escenario_pruebas.sql
-- Descripción: Simula un escenario de pruebas para el sistema TECHXPRESS.
-- Objetivo: Atender 5 clientes con inserciones de datos, llamadas a procedimientos PL/SQL
-- (abrirOrdenTrabajo y facturarCliente), verificaciones con SELECT y pruebas de excepciones.
-- Asume que tablas, procedimientos y triggers están creados (ver Anexos 4.2 y 4.3).
-- Ejecutar como DEV01 o usuario con permisos.
-- =======================================================================================
-- Sección 1: Inserciones de Datos de Ejemplo
-- Insertar 5 clientes en BASE_TABLAS.clientes
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (1, 'Juan Pérez', '555-1234', 'juan@email.com', 'Calle 1');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (2, 'María López', '555-5678', 'maria@email.com', 'Calle 2');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (3, 'Carlos García', '555-9012', 'carlos@email.com', 'Calle 3');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (4, 'Ana Rodríguez', '555-3456', 'ana@email.com', 'Calle 4');
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion) VALUES (5, 'Pedro Martínez', '555-7890', 'pedro@email.com', 'Calle 5');

-- Insertar técnicos en BASE_TABLAS.tecnicos
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (1, 'Técnico A', '555-1111', 'tecnicoa@email.com');
INSERT INTO BASE_TABLAS.tecnicos (idTecnico, nombre, telefono, email) VALUES (2, 'Técnico B', '555-2222', 'tecnicob@email.com');

-- Insertar servicios en BASE_TABLAS.servicios
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (1, 'Reparación de pantalla', 500.00);
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (2, 'Cambio de batería', 200.00);
INSERT INTO BASE_TABLAS.servicios (idServicio, descripcion, costo) VALUES (3, 'Limpieza interna', 100.00);

-- Insertar equipos en OPS_TABLAS.equipos (uno por cliente)
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (1, 1, 'Laptop', 'Dell', 'XPS 13', 'SN001');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (2, 2, 'Teléfono', 'Samsung', 'Galaxy S21', 'SN002');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (3, 3, 'Tablet', 'Apple', 'iPad Pro', 'SN003');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (4, 4, 'Laptop', 'HP', 'Pavilion', 'SN004');
INSERT INTO OPS_TABLAS.equipos (idEquipo, idCliente, tipo_equipo, marca, modelo, numero_serie) VALUES (5, 5, 'Teléfono', 'Xiaomi', 'Mi 11', 'SN005');

COMMIT;

-- Sección 2: Atención de Clientes (Llamadas a Procedimientos)
-- Escenario: Atender 5 clientes abriendo órdenes de trabajo y facturando.
-- Cliente 1: Abrir orden con 2 servicios, luego facturar.
EXEC DEV01.abrirOrdenTrabajo(1, 1, 1, 2, NULL, SYSDATE);
EXEC DEV01.facturarCliente(1);

-- Cliente 2: Abrir orden con 1 servicio, luego facturar.
EXEC DEV01.abrirOrdenTrabajo(2, 2, 2, NULL, NULL, SYSDATE);
EXEC DEV01.facturarCliente(2);

-- Cliente 3: Abrir orden con 3 servicios, luego facturar.
EXEC DEV01.abrirOrdenTrabajo(3, 3, 1, 2, 3, SYSDATE);
EXEC DEV01.facturarCliente(3);

-- Cliente 4: Abrir orden con 1 servicio, luego facturar.
EXEC DEV01.abrirOrdenTrabajo(4, 4, 3, NULL, NULL, SYSDATE);
EXEC DEV01.facturarCliente(4);

-- Cliente 5: Abrir orden con 2 servicios, luego facturar.
EXEC DEV01.abrirOrdenTrabajo(5, 5, 1, 3, NULL, SYSDATE);
EXEC DEV01.facturarCliente(5);

-- Sección 3: Verificaciones con SELECT
-- Verificar órdenes creadas
SELECT * FROM OPS_TABLAS.ordenestrabajo;

-- Verificar asociaciones de servicios
SELECT * FROM OPS_TABLAS.ordenes_servicio;

-- Verificar facturas actualizadas
SELECT * FROM FACT_TABLAS.facturas;

-- Verificar auditoría de clientes
SELECT * FROM BASE_TABLAS.auditoria_clientes;

-- Verificar auditoría de facturas
SELECT * FROM FACT_TABLAS.auditoria_facturas;

-- Sección 4: Pruebas de Excepciones
-- Prueba 1: Cliente no existe (ORA-20001)
-- EXEC DEV01.abrirOrdenTrabajo(999, 1, 1, NULL, NULL, SYSDATE); -- Descomentar para probar

-- Prueba 2: Equipo no existe (ORA-20002)
-- EXEC DEV01.abrirOrdenTrabajo(1, 999, 1, NULL, NULL, SYSDATE); -- Descomentar para probar

-- Prueba 3: Equipo no pertenece al cliente (ORA-20003)
-- EXEC DEV01.abrirOrdenTrabajo(1, 2, 1, NULL, NULL, SYSDATE); -- Descomentar para probar

-- Prueba 4: No hay técnico disponible (ORA-20004) - Simular sobrecarga insertando órdenes previas
-- INSERT INTO OPS_TABLAS.ordenestrabajo (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, idFactura) VALUES (OPS_TABLAS.seq_ordenestrabajo.NEXTVAL, 1, 1, SYSDATE, SYSDATE+3, 'ABIERTA', 1);
-- EXEC DEV01.abrirOrdenTrabajo(1, 1, 1, NULL, NULL, SYSDATE); -- Descomentar para probar

-- Prueba 5: Cliente sin factura para facturar (ORA-20005)
-- EXEC DEV01.facturarCliente(999); -- Descomentar para probar

-- Prueba 6: No hay órdenes con servicios (ORA-20006) - Crear factura vacía y probar
-- INSERT INTO FACT_TABLAS.facturas (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente) VALUES (FACT_TABLAS.seq_facturas.NEXTVAL, SYSDATE, 0, 'PENDIENTE', 6);
-- EXEC DEV01.facturarCliente(6); -- Descomentar para probar

-- Fin del archivo
-- =======================================================================================