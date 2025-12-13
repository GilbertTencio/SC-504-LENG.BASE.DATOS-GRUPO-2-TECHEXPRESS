-- =======================================================================================
-- 4.3. PROCEDIMIENTOS, FUNCIONES, TRIGGERS - TECHXPRESS
-- Scripts para crear procedimientos PL/SQL, triggers de auditoría.
-- Ejecutar en DEV01 para procedimientos, y en esquemas respectivos para triggers.
-- =======================================================================================

-- En DEV01: Procedimiento abrirOrdenTrabajo
CREATE OR REPLACE NONEDITIONABLE PROCEDURE abrirOrdenTrabajo (
    p_idCliente    IN BASE_TABLAS.CLIENTES.idCliente%TYPE,
    p_idEquipo     IN OPS_TABLAS.EQUIPOS.idEquipo%TYPE,
    p_idServicio1  IN BASE_TABLAS.SERVICIOS.idServicio%TYPE,
    p_idServicio2  IN BASE_TABLAS.SERVICIOS.idServicio%TYPE DEFAULT NULL,
    p_idServicio3  IN BASE_TABLAS.SERVICIOS.idServicio%TYPE DEFAULT NULL,
    p_fechaIngreso IN DATE
) AS
    v_idClienteEquipo   OPS_TABLAS.EQUIPOS.idCliente%TYPE;
    v_idTecnico         BASE_TABLAS.TECNICOS.idTecnico%TYPE;
    v_idFactura         FACT_TABLAS.FACTURAS.id_factura%TYPE;
    v_idOrden           OPS_TABLAS.ORDENESTRABAJO.idOrden%TYPE;
    v_fechaEntrega      DATE;

    e_cliente_no_existe        EXCEPTION;
    e_equipo_no_existe         EXCEPTION;
    e_equipo_no_del_cliente    EXCEPTION;
    e_sin_tecnico_disponible   EXCEPTION;

BEGIN
    -- Validar cliente
    DECLARE
        v_dummy NUMBER;
    BEGIN
        SELECT 1 INTO v_dummy FROM BASE_TABLAS.CLIENTES WHERE idCliente = p_idCliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_cliente_no_existe;
    END;

    -- Validar equipo y pertenencia
    BEGIN
        SELECT idCliente INTO v_idClienteEquipo FROM OPS_TABLAS.EQUIPOS WHERE idEquipo = p_idEquipo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_equipo_no_existe;
    END;
    IF v_idClienteEquipo <> p_idCliente THEN RAISE e_equipo_no_del_cliente; END IF;

    -- Calcular fecha_entrega
    v_fechaEntrega := p_fechaIngreso + 3;

    -- Buscar técnico disponible
    BEGIN
        SELECT t.idTecnico INTO v_idTecnico FROM BASE_TABLAS.TECNICOS t
        WHERE NOT EXISTS (
            SELECT 1 FROM OPS_TABLAS.ORDENESTRABAJO ot
            WHERE ot.idTecnico = t.idTecnico
            AND ot.fecha_ingreso <= v_fechaEntrega
            AND NVL(ot.fecha_entrega, ot.fecha_ingreso + 3) >= p_fechaIngreso
        ) AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_sin_tecnico_disponible;
    END;

    -- Buscar o crear factura
    BEGIN
        SELECT f.id_factura INTO v_idFactura FROM FACT_TABLAS.FACTURAS f WHERE f.clientes_id_cliente = p_idCliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT FACT_TABLAS.seq_facturas.NEXTVAL INTO v_idFactura FROM dual;
            INSERT INTO FACT_TABLAS.FACTURAS (id_factura, fecha_factura, total, metodo_pago, clientes_id_cliente)
            VALUES (v_idFactura, p_fechaIngreso, 0, 'PENDIENTE', p_idCliente);
    END;

    -- Crear orden
    SELECT OPS_TABLAS.seq_ordenestrabajo.NEXTVAL INTO v_idOrden FROM dual;
    INSERT INTO OPS_TABLAS.ORDENESTRABAJO (idOrden, idEquipo, idTecnico, fecha_ingreso, fecha_entrega, estado, observaciones, idFactura)
    VALUES (v_idOrden, p_idEquipo, v_idTecnico, p_fechaIngreso, v_fechaEntrega, 'ABIERTA', NULL, v_idFactura);

    -- Asociar servicios
    IF p_idServicio1 IS NOT NULL THEN
        INSERT INTO OPS_TABLAS.ORDENES_SERVICIO (idOrden, idServicio, cantidad) VALUES (v_idOrden, p_idServicio1, 1);
    END IF;
    IF p_idServicio2 IS NOT NULL THEN
        INSERT INTO OPS_TABLAS.ORDENES_SERVICIO (idOrden, idServicio, cantidad) VALUES (v_idOrden, p_idServicio2, 1);
    END IF;
    IF p_idServicio3 IS NOT NULL THEN
        INSERT INTO OPS_TABLAS.ORDENES_SERVICIO (idOrden, idServicio, cantidad) VALUES (v_idOrden, p_idServicio3, 1);
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_cliente_no_existe THEN RAISE_APPLICATION_ERROR(-20001, 'Orden rechazada: cliente no existe.');
    WHEN e_equipo_no_existe THEN RAISE_APPLICATION_ERROR(-20002, 'Orden rechazada: equipo no existe.');
    WHEN e_equipo_no_del_cliente THEN RAISE_APPLICATION_ERROR(-20003, 'Orden rechazada: equipo no pertenece al cliente.');
    WHEN e_sin_tecnico_disponible THEN RAISE_APPLICATION_ERROR(-20004, 'Orden rechazada: no hay técnico disponible.');
    WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20999, 'Error: ' || SQLCODE || ' - ' || SQLERRM);
END abrirOrdenTrabajo;
/

-- En DEV01: Procedimiento facturarCliente
CREATE OR REPLACE PROCEDURE facturarCliente (
    p_idCliente IN BASE_TABLAS.CLIENTES.idCliente%TYPE
) AS
    v_idFactura FACT_TABLAS.FACTURAS.id_factura%TYPE;
    v_totalFactura NUMBER(10,2) := 0;
    e_factura_no_existe EXCEPTION;
    e_sin_ordenes EXCEPTION;
BEGIN
    -- Encontrar factura
    BEGIN
        SELECT f.id_factura INTO v_idFactura FROM FACT_TABLAS.FACTURAS f WHERE f.clientes_id_cliente = p_idCliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_factura_no_existe;
    END;

    -- Calcular total
    BEGIN
        SELECT SUM(os.cantidad * s.costo) INTO v_totalFactura
        FROM OPS_TABLAS.ORDENESTRABAJO ot
        JOIN OPS_TABLAS.ORDENES_SERVICIO os ON ot.idOrden = os.idOrden
        JOIN BASE_TABLAS.SERVICIOS s ON os.idServicio = s.idServicio
        WHERE ot.idFactura = v_idFactura;
        IF v_totalFactura IS NULL THEN RAISE e_sin_ordenes; END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_sin_ordenes;
    END;

    -- Actualizar factura
    UPDATE FACT_TABLAS.FACTURAS SET total = v_totalFactura, metodo_pago = 'EFECTIVO' WHERE id_factura = v_idFactura;
    COMMIT;
EXCEPTION
    WHEN e_factura_no_existe THEN RAISE_APPLICATION_ERROR(-20005, 'Facturación rechazada: cliente sin factura.');
    WHEN e_sin_ordenes THEN RAISE_APPLICATION_ERROR(-20006, 'Facturación rechazada: no hay órdenes con servicios.');
    WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20999, 'Error: ' || SQLCODE || ' - ' || SQLERRM);
END facturarCliente;
/

-- En BASE_TABLAS: Trigger para clientes
CREATE SEQUENCE seq_auditoria_clientes START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE TABLE auditoria_clientes (
    id_auditoria NUMBER(10) PRIMARY KEY,
    tabla VARCHAR2(50) DEFAULT 'clientes',
    accion VARCHAR2(10),
    id_registro NUMBER(10),
    fecha_hora TIMESTAMP DEFAULT SYSTIMESTAMP,
    usuario VARCHAR2(50) DEFAULT USER
);
CREATE OR REPLACE TRIGGER trg_auditoria_clientes
AFTER INSERT OR UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO auditoria_clientes (id_auditoria, accion, id_registro) VALUES (seq_auditoria_clientes.NEXTVAL, 'INSERT', :NEW.idCliente);
    ELSIF UPDATING THEN
        INSERT INTO auditoria_clientes (id_auditoria, accion, id_registro) VALUES (seq_auditoria_clientes.NEXTVAL, 'UPDATE', :NEW.idCliente);
    END IF;
END;
/

-- En FACT_TABLAS: Trigger para facturas
CREATE SEQUENCE seq_auditoria_facturas START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE TABLE auditoria_facturas (
    id_auditoria NUMBER(10) PRIMARY KEY,
    tabla VARCHAR2(50) DEFAULT 'facturas',
    accion VARCHAR2(10),
    id_registro NUMBER(10),
    fecha_hora TIMESTAMP DEFAULT SYSTIMESTAMP,
    usuario VARCHAR2(50) DEFAULT USER
);
CREATE OR REPLACE TRIGGER trg_auditoria_facturas
AFTER INSERT OR UPDATE ON facturas
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO auditoria_facturas (id_auditoria, accion, id_registro) VALUES (seq_auditoria_facturas.NEXTVAL, 'INSERT', :NEW.id_factura);
    ELSIF UPDATING THEN
        INSERT INTO auditoria_facturas (id_auditoria, accion, id_registro) VALUES (seq_auditoria_facturas.NEXTVAL, 'UPDATE', :NEW.id_factura);
    END IF;
END;
/

-- Fin del script