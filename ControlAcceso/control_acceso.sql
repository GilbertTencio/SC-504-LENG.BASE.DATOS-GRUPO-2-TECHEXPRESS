-- =======================================================================================
-- 4.1. CONTROL DE ACCESO - TECHXPRESS
-- Scripts para crear usuarios, roles y otorgar permisos.
-- Ejecutar como SYSTEM inicialmente.
-- =======================================================================================

-- Configuración inicial
ALTER SESSION SET "_oracle_script"=true;

-- Crear usuarios principales
CREATE USER base_tablas IDENTIFIED BY base_tablas
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

CREATE USER ops_tablas IDENTIFIED BY ops_tablas
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

CREATE USER fact_tablas IDENTIFIED BY fact_tablas
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

-- Otorgar permisos básicos a usuarios principales
GRANT CREATE SESSION, CREATE TABLE TO base_tablas;
GRANT CREATE SESSION, CREATE TABLE TO ops_tablas;
GRANT CREATE SESSION, CREATE TABLE TO fact_tablas;

-- Crear usuarios de desarrollo y finales
CREATE USER dev01 IDENTIFIED BY dev01 TEMPORARY TABLESPACE temp;
CREATE USER usr_final01 IDENTIFIED BY usr_final01 TEMPORARY TABLESPACE temp;

-- Crear roles
CREATE ROLE roldev;
GRANT CREATE SESSION, CREATE PROCEDURE, CREATE VIEW, CREATE ROLE TO roldev;

CREATE ROLE rol_usrfinal;
GRANT CREATE SESSION TO rol_usrfinal;

CREATE ROLE rol_app_final;
GRANT CREATE SESSION TO rol_app_final;

-- Asignar roles a usuarios
GRANT roldev TO dev01;
GRANT rol_usrfinal TO usr_final01;

-- Otorgar permisos adicionales
GRANT CREATE PROCEDURE TO base_tablas;

-- Permisos para esquemas cruzados (ejecutar después de crear tablas)
-- GRANT REFERENCES ON BASE_TABLAS.clientes TO ops_tablas;
-- GRANT REFERENCES ON BASE_TABLAS.tecnicos TO ops_tablas;
-- GRANT REFERENCES ON BASE_TABLAS.servicios TO ops_tablas;
-- GRANT REFERENCES ON OPS_TABLAS.ordenestrabajo TO fact_tablas;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON FACT_TABLAS.facturas TO DEV01;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON OPS_TABLAS.ordenestrabajo TO DEV01;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON OPS_TABLAS.ordenes_servicio TO DEV01;
-- GRANT SELECT ON OPS_TABLAS.equipos TO DEV01;
-- GRANT SELECT ON OPS_TABLAS.seq_ordenestrabajo TO DEV01;
-- GRANT SELECT ON FACT_TABLAS.seq_facturas TO DEV01;
-- GRANT EXECUTE ON DEV01.abrirOrdenTrabajo TO rol_app_final;
-- GRANT EXECUTE ON DEV01.facturarCliente TO rol_app_final;

-- Fin del script