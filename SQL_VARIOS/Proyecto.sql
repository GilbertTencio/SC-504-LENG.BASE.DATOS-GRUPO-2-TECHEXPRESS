-- =======================================================================================
-- PROYECTO TECHXPRESS - SCRIPT COMPLETO DE IMPLEMENTACIÓN
-- Grupo 2 - Basado en la bitácora de clase hasta semana 8
-- Este script crea todo el proyecto desde cero: usuarios, esquemas, tablas, permisos,
-- roles, procedimientos, pruebas y verificaciones.
-- Estandarización aplicada: Nombres de columnas y tablas en español (como en clase, ej. idCliente en lugar de id_cliente).
-- Tipos de datos ajustados para consistencia: observaciones como VARCHAR2(200) (no CLOB), stock como NUMBER(10), etc.
-- No se agregan elementos extras; se limita a lo de la bitácora.
-- Ejecutar como SYSTEM inicialmente, luego cambiar conexiones según indicado.
-- =======================================================================================

-- ===============================================
-- PASO 1: CONECTAR COMO SYSTEM Y EJECUTAR CONFIGURACIÓN INICIAL
-- ===============================================
-- Conectar como SYSTEM (usuario: system, contraseña: la de tu instalación Oracle).
-- Ejecutar este comando para permitir creación de usuarios sin restricciones.
ALTER SESSION SET "_oracle_script"=true;

-- ===============================================
-- PASO 2: CREAR USUARIOS PRINCIPALES (BASE_TABLAS, OPS_TABLAS, FACT_TABLAS)
-- ===============================================
-- Crear usuarios con cuotas ilimitadas en tablespace users.
CREATE USER base_tablas IDENTIFIED BY base_tablas
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

CREATE USER ops_tablas IDENTIFIED BY ops_tablas
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

CREATE USER fact_tablas IDENTIFIED BY fact_tablas
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

-- ===============================================
-- PASO 3: REVISAR DICCIONARIO DE DATOS PARA LOS USUARIOS CREADOS
-- ===============================================
-- Ejecutar estas consultas en SYSTEM para verificar usuarios creados.
-- (Comentadas aquí; ejecutar manualmente si se desea verificar durante el script).
-- SELECT username, default_tablespace, temporary_tablespace
-- FROM dba_users
-- WHERE username IN ('BASE_TABLAS', 'OPS_TABLAS', 'FACT_TABLAS');

-- ===============================================
-- PASO 4: OTORGAR PRIVILEGIOS DE SISTEMA A LOS USUARIOS
-- ===============================================
-- Otorgar permisos para conectarse y crear tablas.
GRANT CREATE SESSION, CREATE TABLE TO base_tablas;
GRANT CREATE SESSION, CREATE TABLE TO ops_tablas;
GRANT CREATE SESSION, CREATE TABLE TO fact_tablas;

-- ===============================================
-- PASO 5: CREAR CONEXIONES (INSTRUCCIÓN PARA EL USUARIO)
-- ===============================================
-- Crear conexiones en SQL Developer o herramienta similar:
-- - Nombre: BASE_TABLAS, Usuario: base_tablas, Contraseña: base_tablas
-- - Nombre: OPS_TABLAS, Usuario: ops_tablas, Contraseña: ops_tablas
-- - Nombre: FACT_TABLAS, Usuario: fact_tablas, Contraseña: fact_tablas
-- Ver video de clase ~1:20 mins para detalles.

-- ===============================================
-- PASO 6: REVISAR CONFIGURACIÓN (OPCIONAL, EN SYSTEM)
-- ===============================================
-- Ejecutar estas consultas en SYSTEM para revisar configuración.
-- (Comentadas; ejecutar manualmente).
-- SELECT username, default_tablespace, temporary_tablespace FROM dba_users WHERE username LIKE 'TABLAS%';
-- SELECT * FROM dba_ts_quotas WHERE username LIKE 'TABLAS%';
-- SELECT * FROM dba_sys_privs WHERE grantee LIKE 'TABLAS%';
-- SELECT owner, object_name, object_type FROM dba_objects WHERE owner LIKE 'TABLAS%' ORDER BY 1,3,2;
-- SELECT * FROM dba_tab_privs WHERE grantee LIKE 'TABLAS%';

-- ===============================================
-- PASO 7: CONECTAR COMO BASE_TABLAS Y CREAR TABLAS BASE
-- ===============================================
-- Cambiar conexión a BASE_TABLAS.
-- Crear tablas base: clientes, tecnicos, servicios, repuestos, usuarios.
-- Estandarización: Nombres en español, tipos consistentes.

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

CREATE TABLE repuestos (
  idRepuesto NUMBER(10) CONSTRAINT pk_repuestos PRIMARY KEY,
  nombre VARCHAR2(100) NOT NULL,
  descripcion VARCHAR2(200),
  stock NUMBER(10) DEFAULT 0,
  precio_unitario NUMBER(10,2) NOT NULL
);

CREATE TABLE usuarios (
  idUsuario NUMBER(10) CONSTRAINT pk_usuarios PRIMARY KEY,
  nombre_usuario VARCHAR2(50) NOT NULL,
  contrasenia VARCHAR2(255) NOT NULL,
  nombre_completo VARCHAR2(100),
  email VARCHAR2(100),
  rol VARCHAR2(20),
  activo NUMBER(1),
  fecha_creacion TIMESTAMP
);

-- ===============================================
-- PASO 8: VER OBJETOS EN SYSTEM (DESPUÉS DE CREAR TABLAS EN BASE_TABLAS)
-- ===============================================
-- Cambiar a SYSTEM y ejecutar:
-- SELECT owner, object_name, object_type
-- FROM dba_objects
-- WHERE owner LIKE 'TABLAS%'
-- ORDER BY 1,3,2;

-- ===============================================
-- PASO 9: OTORGAR PERMISOS DESDE BASE_TABLAS A OPS_TABLAS
-- ===============================================
-- Cambiar a BASE_TABLAS y otorgar REFERENCES para FKs.
GRANT REFERENCES ON clientes TO ops_tablas;
GRANT REFERENCES ON tecnicos TO ops_tablas;
GRANT REFERENCES ON servicios TO ops_tablas;
GRANT REFERENCES ON repuestos TO ops_tablas;

-- ===============================================
-- PASO 10: CONECTAR COMO OPS_TABLAS Y CREAR TABLAS OPERATIVAS
-- ===============================================
-- Cambiar conexión a OPS_TABLAS.
-- Crear tablas: equipos, ordenestrabajo, ordenes_servicios, ordenes_repuestos.
-- Usar FKs con esquema BASE_TABLAS.

CREATE TABLE equipos (
  idEquipo NUMBER(10) CONSTRAINT pk_equipos PRIMARY KEY,
  idCliente NUMBER(10) NOT NULL
    CONSTRAINT fk_equipo_cliente REFERENCES BASE_TABLAS.clientes(idCliente),
  tipo_equipo VARCHAR2(50),
  marca VARCHAR2(50),
  modelo VARCHAR2(50),
  numero_serie VARCHAR2(100)
);

CREATE TABLE ordenestrabajo (
  idOrden NUMBER(10) CONSTRAINT pk_ordenestrabajo PRIMARY KEY,
  idEquipo NUMBER(10) NOT NULL
    CONSTRAINT fk_orden_equipo REFERENCES equipos(idEquipo),
  idTecnico NUMBER(10)
    CONSTRAINT fk_orden_tecnico REFERENCES BASE_TABLAS.tecnicos(idTecnico),
  fecha_ingreso DATE,
  fecha_entrega DATE,
  estado VARCHAR2(20),
  observaciones VARCHAR2(200)
);

CREATE TABLE ordenes_servicios (
  idOrdenServicio NUMBER(10) CONSTRAINT pk_ordenes_servicios PRIMARY KEY,
  idOrden NUMBER(10) NOT NULL
    CONSTRAINT fk_ordsrv_orden REFERENCES ordenestrabajo(idOrden),
  idServicio NUMBER(10) NOT NULL
    CONSTRAINT fk_ordsrv_servicio REFERENCES BASE_TABLAS.servicios(idServicio),
  cantidad NUMBER
);

CREATE TABLE ordenes_repuestos (
  idOrdenRepuesto NUMBER(10) CONSTRAINT pk_ordenes_repuestos PRIMARY KEY,
  idOrden NUMBER(10) NOT NULL
    CONSTRAINT fk_ordrep_orden REFERENCES ordenestrabajo(idOrden),
  idRepuesto NUMBER(10) NOT NULL
    CONSTRAINT fk_ordrep_repuesto REFERENCES BASE_TABLAS.repuestos(idRepuesto),
  cantidad NUMBER
);

-- ===============================================
-- PASO 11: OTORGAR PERMISOS PARA FK DESDE OPS_TABLAS A FACT_TABLAS
-- ===============================================
-- En OPS_TABLAS, otorgar REFERENCES en ordenestrabajo.
GRANT REFERENCES ON ordenestrabajo TO fact_tablas;

-- ===============================================
-- PASO 12: CONECTAR COMO FACT_TABLAS Y CREAR TABLA DE FACTURAS
-- ===============================================
-- Cambiar conexión a FACT_TABLAS.
CREATE TABLE facturas (
  idFactura NUMBER(10) CONSTRAINT pk_facturas PRIMARY KEY,
  idOrden NUMBER(10) NOT NULL
    CONSTRAINT fk_factura_orden REFERENCES OPS_TABLAS.ordenestrabajo(idOrden),
  fecha_factura DATE,
  total NUMBER(10,2),
  metodo_pago VARCHAR2(20)
);

-- ===============================================
-- PASO 13: VER TABLAS CREADAS EN SYSTEM
-- ===============================================
-- Cambiar a SYSTEM y ejecutar:
-- SELECT owner, object_name, object_type
-- FROM dba_objects
-- WHERE owner IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS')
-- ORDER BY 1,3,2;

-- ===============================================
-- PASO 14: COMANDOS PARA SEMANA 7 - CREAR DEVS Y ROLES
-- ===============================================
-- Cambiar a SYSTEM.
-- Crear devs.
ALTER SESSION SET "_oracle_script" = TRUE;

CREATE USER dev01 IDENTIFIED BY dev01 TEMPORARY TABLESPACE temp;
CREATE USER dev02 IDENTIFIED BY dev02 TEMPORARY TABLESPACE temp;
CREATE USER dev03 IDENTIFIED BY dev03 TEMPORARY TABLESPACE temp;
CREATE USER dev04 IDENTIFIED BY dev04 TEMPORARY TABLESPACE temp;

-- Crear rol general para desarrollo.
CREATE ROLE roldev;
GRANT create session, create procedure, create view, create role TO roldev;

-- Asignar rol a devs.
GRANT roldev TO dev01;
GRANT roldev TO dev02;
GRANT roldev TO dev03;
GRANT roldev TO dev04;

-- ===============================================
-- PASO 15: REVISAR DICCIONARIO PARA PROYECTO (EN SYSTEM)
-- ===============================================
-- Ejecutar consultas en SYSTEM (comentadas).
-- SELECT username, default_tablespace, temporary_tablespace FROM dba_users WHERE username IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS') OR username LIKE 'DEV%';
-- SELECT * FROM dba_ts_quotas WHERE username IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS') OR username LIKE 'DEV%';
-- SELECT * FROM dba_sys_privs WHERE grantee IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS','ROLDEV') OR grantee LIKE 'DEV%';
-- SELECT owner, object_name, object_type FROM dba_objects WHERE owner IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS') OR owner LIKE 'DEV%' ORDER BY 1,3,2;
-- SELECT * FROM dba_tab_privs WHERE grantee IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS','ROLDEV') OR grantee LIKE 'DEV%';
-- SELECT * FROM dba_roles WHERE role = 'ROLDEV' OR role LIKE 'ROLDEV%';
-- SELECT * FROM dba_role_privs WHERE granted_role = 'ROLDEV' OR granted_role LIKE 'ROLDEV%' ORDER BY 2;

-- ===============================================
-- PASO 16: COMANDOS PARA PROYECTO FINAL SEMANA 7
-- ===============================================
-- Cambiar a SYSTEM.
-- Crear roles y usuarios finales.
ALTER SESSION SET "_oracle_script" = TRUE;

-- Rol de desarrollo (ya creado arriba, pero repetir si necesario).
-- CREATE ROLE roldev; -- Ya hecho.

-- Rol del usuario final.
CREATE ROLE rol_usrfinal;
GRANT CREATE SESSION TO rol_usrfinal;

-- Usuario desarrollador (ya creado).
-- CREATE USER dev01 IDENTIFIED BY dev01 TEMPORARY TABLESPACE temp; -- Ya hecho.
-- GRANT roldev TO dev01; -- Ya hecho.

-- Usuario final.
CREATE USER usr_final01 IDENTIFIED BY usr_final01 TEMPORARY TABLESPACE temp;
GRANT rol_usrfinal TO usr_final01;

-- ===============================================
-- PASO 17: CREAR CONEXIONES PARA USUARIOS FINALES (INSTRUCCIÓN)
-- ===============================================
-- Crear conexiones:
-- - Nombre: USR_FINAL01, Usuario: usr_final01, Contraseña: usr_final01
-- - Nombre: DEV01, Usuario: dev01, Contraseña: dev01

-- ===============================================
-- PASO 18: OTORGAR PERMISO A BASE_TABLAS PARA CREAR PROCEDIMIENTOS
-- ===============================================
-- Cambiar a SYSTEM.
GRANT CREATE PROCEDURE TO base_tablas;

-- ===============================================
-- PASO 19: CONECTAR COMO DEV01 Y CREAR PROCEDIMIENTO
-- ===============================================
-- Cambiar a DEV01.
CREATE OR REPLACE PROCEDURE insertarClienteFinal(
  p_id_cliente   NUMBER,
  p_nombre       VARCHAR2,
  p_telefono     VARCHAR2,
  p_email        VARCHAR2,
  p_direccion    VARCHAR2
) AS
BEGIN
  INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion)
  VALUES (p_id_cliente, p_nombre, p_telefono, p_email, p_direccion);
  COMMIT;
END;
/

-- Ejecutar prueba en DEV01.
EXEC insertarClienteFinal(5001, 'Cliente Procedimiento DEV01', '8888-5555', 'cliente5001@example.com', 'San José');

-- ===============================================
-- PASO 20: CREAR ROL APP Y OTORGAR PERMISOS EN BASE_TABLAS
-- ===============================================
-- Cambiar a BASE_TABLAS.
CREATE ROLE rol_app_final;
GRANT EXECUTE ON insertarClienteFinal TO rol_app_final;

-- ===============================================
-- PASO 21: OTORGAR PERMISOS SOBRE TABLA CLIENTES DESDE DEV01 Y BASE_TABLAS
-- ===============================================
-- En DEV01.
GRANT SELECT, INSERT, UPDATE, DELETE ON BASE_TABLAS.clientes TO dev01;

-- En BASE_TABLAS.
GRANT SELECT, INSERT, UPDATE, DELETE ON clientes TO dev01;

-- ===============================================
-- PASO 22: PRUEBA DE INSERCIÓN EN DEV01
-- ===============================================
-- En DEV01.
INSERT INTO BASE_TABLAS.clientes (idCliente, nombre, telefono, email, direccion)
VALUES (3001, 'Cliente DEV01', '9999-1111', 'dev01@example.com', 'Cartago');
-- Debe mostrar 1 fila insertada.

-- ===============================================
-- PASO 23: VERIFICAR EN BASE_TABLAS
-- ===============================================
-- En BASE_TABLAS.
SELECT idCliente, nombre, telefono, email, direccion
FROM clientes
WHERE idCliente = 3001;  -- Cambié a 3001 para coincidir con la inserción.

-- ===============================================
-- PASO 24: PROBAR ACCESO RESTRINGIDO EN USR_FINAL01
-- ===============================================
-- En USR_FINAL01.
-- SELECT SYSDATE FROM dual;  -- Debe funcionar.
-- SELECT * FROM BASE_TABLAS.clientes;  -- Debe fallar.
-- EXEC BASE_TABLAS.insertarClienteFinal(2,'Prueba','8888','x@x.com','San José');  -- Debe fallar.

-- ===============================================
-- PASO 25: VERIFICACIONES FINALES EN SYSTEM
-- ===============================================
-- En SYSTEM, ejecutar consultas (comentadas).
-- SELECT username, default_tablespace, temporary_tablespace FROM dba_users WHERE username IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS','USR_FINAL01') OR username LIKE 'USR_FINAL%' ORDER BY 1;
-- SELECT * FROM dba_ts_quotas WHERE username IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS','USR_FINAL01') OR username LIKE 'USR_FINAL%' ORDER BY 1;
-- SELECT * FROM dba_sys_privs WHERE grantee IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS','ROL_FINAL','ROL_APP_FINAL','USR_FINAL01') ORDER BY 1;
-- SELECT owner, object_name, object_type FROM dba_objects WHERE owner IN ('BASE_TABLAS','OPS_TABLAS','FACT_TABLAS','USR_FINAL01') ORDER BY 1,3,2;
-- SELECT * FROM dba_tab_privs WHERE grantee IN ('ROL_FINAL','ROL_APP_FINAL','USR_FINAL01','BASE_TABLAS','OPS_TABLAS','FACT_TABLAS') ORDER BY 1;
-- SELECT * FROM dba_roles WHERE role IN ('ROL_FINAL','ROL_APP_FINAL');
-- SELECT * FROM dba_role_privs WHERE granted_role IN ('ROL_FINAL','ROL_APP_FINAL') ORDER BY 2;

-- ===============================================
-- 
-- ===============================================
DSD LA CONEXION BASE_TABLAS CONEXION 
-----------------------------------
****************************
OPCIONAL = VER SI YA EXISTE LA TABLA 
-- Si NO existen, descomentar estos CREATE TABLE

-- CREATE TABLE clientes (
--     idCliente   NUMBER(10)      PRIMARY KEY,
--     nombre      VARCHAR2(100)   NOT NULL,
--     telefono    VARCHAR2(20),
--     email       VARCHAR2(100),
--     direccion   VARCHAR2(200)
-- );

-- CREATE TABLE tecnicos (
--     idTecnico   NUMBER(10)      PRIMARY KEY,
--     nombre      VARCHAR2(100)   NOT NULL,
--     telefono    VARCHAR2(20),
--     email       VARCHAR2(100)
-- );

-- CREATE TABLE servicios (
--     idServicio  NUMBER(10)      PRIMARY KEY,
--     descripcion VARCHAR2(200)   NOT NULL,
--     costo       NUMBER(10,2)    NOT NULL
-- );

-- Ver estructura (para comprobar que quedó igual )
DESC clientes;
DESC tecnicos;
DESC servicios;

-----------------------------------
****************************-----------------------------------
****************************
DSD LA CONEXCION SYSTEM 

-- Crear secuencia de órdenes de trabajo para OPS_TABLAS
--------------------------------------------------------
CREATE SEQUENCE OPS_TABLAS.seq_ordenestrabajo
  START WITH 1
  INCREMENT BY 1
  NOCACHE;

--------------------------------------------------------
-- Crear secuencia de facturas para FACT_TABLAS
--------------------------------------------------------
CREATE SEQUENCE FACT_TABLAS.seq_facturas
  START WITH 1
  INCREMENT BY 1
  NOCACHE;


-----------------------------------
****************************-----------------------------------
****************************

DSD Conexión: OPS_TABLAS CONEXION
-- 1)  ver tablas actuales
SELECT table_name FROM user_tables

-- Si ya existía una versión vieja de ORDENESTRABAJO, la borramos:
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ordenestrabajo CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN  -- -942 = table or view does not exist
      RAISE;
    END IF;
END;
/


-- 3) CREAR LAS TABLAS CORRECTAS

-- EQUIPOS (si ya la tienen bien, se puede omitir este CREATE;
-- )

 CREATE TABLE equipos (
     idEquipo     NUMBER(10)      PRIMARY KEY,
     idCliente    NUMBER(10)      NOT NULL,
     tipo_equipo  VARCHAR2(50)    NOT NULL,
     marca        VARCHAR2(50),
     modelo       VARCHAR2(50),
     numero_serie VARCHAR2(100)
 );



-- ORDENES DE TRABAJO
CREATE TABLE ordenestrabajo (
    idOrden       NUMBER(10)      PRIMARY KEY,
    idEquipo      NUMBER(10)      NOT NULL,
    idTecnico     NUMBER(10)      NOT NULL,
    fecha_ingreso DATE            NOT NULL,
    fecha_entrega DATE,
    estado        VARCHAR2(20)    NOT NULL,
    observaciones CLOB,
    idFactura     NUMBER(10)      NOT NULL
);


-- Estados permitidos (pueden ajustarse según lo que el profe quiera)
ALTER TABLE ordenestrabajo ADD CONSTRAINT ordenes_estado_chk
  CHECK (estado IN ('ABIERTA','EN_PROCESO','CERRADA','CANCELADA'));


-- ORDENES_SERVICIO
CREATE TABLE ordenes_servicio (
    idOrden     NUMBER(10)  NOT NULL,
    idServicio  NUMBER(10)  NOT NULL,
    cantidad    NUMBER(10)  NOT NULL,
    CONSTRAINT ordenes_servicio_pk PRIMARY KEY (idOrden, idServicio)
);

-----------------------------------
****************************-----------------------------------
****************************
Conexión: FACT_TABLAS CONEXION

-- 1) Borrar FACTURAS vieja si existe
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE facturas CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN  -- 942 = table does not exist
      RAISE;
    END IF;
END;
/

-- 2) Crear FACTURAS tal como en el diagrama BASADO EN LO Q PIDIO PROFE SEMANA 11
CREATE TABLE facturas (
    id_factura          NUMBER(10)      PRIMARY KEY,
    fecha_factura       DATE            NOT NULL,
    total               NUMBER(10,2)    NOT NULL,
    metodo_pago         VARCHAR2(20)    NOT NULL,
    clientes_id_cliente NUMBER(10)      NOT NULL
);

-- 3) CHECK de método de pago
ALTER TABLE facturas ADD CONSTRAINT facturas_metodo_pago_chk
  CHECK (metodo_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA','PENDIENTE'));

-----------------------------
------------------------------
DESDE CONEXION SYSTEM 
GRANT SELECT, REFERENCES ON BASE_TABLAS.clientes TO FACT_TABLAS;
-------------------------------
--------------------------------
conexión FACT_TABLAS CONEXION

ALTER TABLE facturas ADD CONSTRAINT facturas_clientes_fk
  FOREIGN KEY (clientes_id_cliente)
  REFERENCES BASE_TABLAS.clientes (idCliente);

-------------------------------
--------------------------------
dsd system 

GRANT SELECT, INSERT, UPDATE, DELETE
ON FACT_TABLAS.facturas
TO DEV01;

GRANT SELECT, INSERT, UPDATE, DELETE
ON OPS_TABLAS.ordenestrabajo
TO DEV01;

GRANT SELECT, INSERT, UPDATE, DELETE
ON OPS_TABLAS.ordenes_servicio
TO DEV01;

GRANT SELECT
ON OPS_TABLAS.equipos
TO DEV01;

GRANT SELECT
ON OPS_TABLAS.seq_ordenestrabajo
TO DEV01;

GRANT SELECT ON OPS_TABLAS.seq_ordenestrabajo TO DEV01;
GRANT SELECT ON FACT_TABLAS.seq_facturas       TO DEV01;


-------------------------------
--------------------------------

create or replace NONEDITIONABLE PROCEDURE abrirOrdenTrabajo (
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
    -- 1. Validar cliente
    DECLARE
        v_dummy NUMBER;
    BEGIN
        SELECT 1
        INTO   v_dummy
        FROM   BASE_TABLAS.CLIENTES
        WHERE  idCliente = p_idCliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_cliente_no_existe;
    END;

    -- 2. Validar equipo y que pertenezca al cliente
    BEGIN
        SELECT idCliente
        INTO   v_idClienteEquipo
        FROM   OPS_TABLAS.EQUIPOS
        WHERE  idEquipo = p_idEquipo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_equipo_no_existe;
    END;

    IF v_idClienteEquipo <> p_idCliente THEN
        RAISE e_equipo_no_del_cliente;
    END IF;

    -- 3. fecha_entrega = fecha_ingreso + 3 días
    v_fechaEntrega := p_fechaIngreso + 3;

    -- 4. Buscar técnico disponible sin traslape
    BEGIN
        SELECT t.idTecnico
        INTO   v_idTecnico
        FROM   BASE_TABLAS.TECNICOS t
        WHERE  NOT EXISTS (
                   SELECT 1
                   FROM   OPS_TABLAS.ORDENESTRABAJO ot
                   WHERE  ot.idTecnico      = t.idTecnico
                   AND    ot.fecha_ingreso <= v_fechaEntrega
                   AND    NVL(ot.fecha_entrega,
                             ot.fecha_ingreso + 3) >= p_fechaIngreso
               )
        AND    ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_sin_tecnico_disponible;
    END;

    -- 5. Buscar o crear factura del cliente
    BEGIN
        SELECT f.id_factura
        INTO   v_idFactura
        FROM   FACT_TABLAS.FACTURAS f
        WHERE  f.clientes_id_cliente = p_idCliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT FACT_TABLAS.seq_facturas.NEXTVAL
            INTO   v_idFactura
            FROM   dual;

            INSERT INTO FACT_TABLAS.FACTURAS (
                id_factura,
                fecha_factura,
                total,
                metodo_pago,
                clientes_id_cliente
            ) VALUES (
                v_idFactura,
                p_fechaIngreso,
                0,
                'PENDIENTE',
                p_idCliente
            );
    END;

    -- 6. Crear orden de trabajo
    SELECT OPS_TABLAS.seq_ordenestrabajo.NEXTVAL
    INTO   v_idOrden
    FROM   dual;

    INSERT INTO OPS_TABLAS.ORDENESTRABAJO (
        idOrden,
        idEquipo,
        idTecnico,
        fecha_ingreso,
        fecha_entrega,
        estado,
        observaciones,
        idFactura
    ) VALUES (
        v_idOrden,
        p_idEquipo,
        v_idTecnico,
        p_fechaIngreso,
        v_fechaEntrega,
        'ABIERTA',
        NULL,
        v_idFactura
    );

    -- 7. Insertar órdenes de servicio
    IF p_idServicio1 IS NOT NULL THEN
        INSERT INTO OPS_TABLAS.ORDENES_SERVICIO (
            idOrden,
            idServicio,
            cantidad
        ) VALUES (
            v_idOrden,
            p_idServicio1,
            1
        );
    END IF;

    IF p_idServicio2 IS NOT NULL THEN
        INSERT INTO OPS_TABLAS.ORDENES_SERVICIO (
            idOrden,
            idServicio,
            cantidad
        ) VALUES (
            v_idOrden,
            p_idServicio2,
            1
        );
    END IF;

    IF p_idServicio3 IS NOT NULL THEN
        INSERT INTO OPS_TABLAS.ORDENES_SERVICIO (
            idOrden,
            idServicio,
            cantidad
        ) VALUES (
            v_idOrden,
            p_idServicio3,
            1
        );
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_cliente_no_existe THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Orden rechazada: el cliente con ID ' || p_idCliente ||
            ' no existe en el sistema.'
        );

    WHEN e_equipo_no_existe THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Orden rechazada: el equipo con ID ' || p_idEquipo ||
            ' no existe en el sistema.'
        );

    WHEN e_equipo_no_del_cliente THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Orden rechazada: el equipo ' || p_idEquipo ||
            ' no pertenece al cliente ' || p_idCliente || '.'
        );

    WHEN e_sin_tecnico_disponible THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Orden rechazada: no hay técnicos disponibles para la fecha ' ||
            TO_CHAR(p_fechaIngreso, 'DD/MM/YYYY') ||
            '. Intente con otra fecha.'
        );

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20999,
            'Error en abrirOrdenTrabajo: ' || SQLCODE || ' - ' || SQLERRM
        );
END abrirOrdenTrabajo;


------------------------------------------------
------------------------------------------------
GRANT EXECUTE ON DEV01.ABRIRORDENTRABAJO TO ROL_APP_FINAL;

CREATE OR REPLACE PROCEDURE facturarCliente (
    p_idCliente IN BASE_TABLAS.CLIENTES.idCliente%TYPE
) AS
    v_idFactura         FACT_TABLAS.FACTURAS.id_factura%TYPE;
    v_totalFactura      NUMBER(10,2) := 0;
    v_totalOrden        NUMBER(10,2);
    
    e_factura_no_existe EXCEPTION;
    e_sin_ordenes       EXCEPTION;
    
BEGIN
    -- 1. Encontrar la factura del cliente
    BEGIN
        SELECT f.id_factura
        INTO   v_idFactura
        FROM   FACT_TABLAS.FACTURAS f
        WHERE  f.clientes_id_cliente = p_idCliente;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_factura_no_existe;
    END;
    
    -- 2. Revisar todas las órdenes de trabajo asociadas a la factura
    --    y sumar los costos de los servicios
    BEGIN
        SELECT SUM(os.cantidad * s.costo)
        INTO   v_totalFactura
        FROM   OPS_TABLAS.ORDENESTRABAJO ot
        JOIN   OPS_TABLAS.ORDENES_SERVICIO os ON ot.idOrden = os.idOrden
        JOIN   BASE_TABLAS.SERVICIOS s ON os.idServicio = s.idServicio
        WHERE  ot.idFactura = v_idFactura;
        
        IF v_totalFactura IS NULL THEN
            RAISE e_sin_ordenes;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_sin_ordenes;
    END;
    
    -- 3. Actualizar el total de la factura y método de pago
    UPDATE FACT_TABLAS.FACTURAS
    SET    total = v_totalFactura,
           metodo_pago = 'EFECTIVO'  -- Cambia a 'TARJETA' o 'TRANSFERENCIA' si es necesario
    WHERE  id_factura = v_idFactura;
    
    COMMIT;
    
EXCEPTION
    WHEN e_factura_no_existe THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Facturación rechazada: el cliente con ID ' || p_idCliente ||
            ' no tiene una factura en el sistema.'
        );
    
    WHEN e_sin_ordenes THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Facturación rechazada: no hay órdenes de trabajo con servicios asociados para el cliente ' || p_idCliente || '.'
        );
    
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20999,
            'Error en facturarCliente: ' || SQLCODE || ' - ' || SQLERRM
        );
END facturarCliente;
/

-- Desde DEV01 o SYSTEM
GRANT EXECUTE ON DEV01.FACTURARCLIENTE TO ROL_APP_FINAL;

-- Conectar como USR_FINAL01 (usuario: usr_final01, contraseña: usr_final01)
EXEC DEV01.FACTURARCLIENTE(1);  -- Reemplaza 1 con un ID de cliente válido

SELECT * FROM FACT_TABLAS.FACTURAS WHERE clientes_id_cliente = 1;

































