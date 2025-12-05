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
