--
-- Regression tests for schemas (namespaces)
--

CREATE SCHEMA test_schema_1
       CREATE UNIQUE INDEX abc_a_idx ON abc (a)

       CREATE VIEW abc_view AS
              SELECT a+1 AS a, b+1 AS b FROM abc

       CREATE TABLE abc (
              a serial,
              b int UNIQUE
       );

-- verify that the objects were created
SELECT COUNT(*) FROM pg_class WHERE relnamespace =
    (SELECT oid FROM pg_namespace WHERE nspname = 'test_schema_1');

INSERT INTO test_schema_1.abc DEFAULT VALUES;
INSERT INTO test_schema_1.abc DEFAULT VALUES;
INSERT INTO test_schema_1.abc DEFAULT VALUES;

SELECT * FROM test_schema_1.abc;
SELECT * FROM test_schema_1.abc_view;

-- test IF NOT EXISTS cases
CREATE SCHEMA test_schema_1; -- fail, already exists
CREATE SCHEMA IF NOT EXISTS test_schema_1; -- ok with notice
CREATE SCHEMA IF NOT EXISTS test_schema_1 -- fail, disallowed
       CREATE TABLE abc (
              a serial,
              b int UNIQUE
       );

DROP SCHEMA test_schema_1 CASCADE;

-- verify that the objects were dropped
SELECT COUNT(*) FROM pg_class WHERE relnamespace =
    (SELECT oid FROM pg_namespace WHERE nspname = 'test_schema_1');

-- Should fail. Disallow CREATE SCHEMA by ROLE with insufficient permission
CREATE ROLE regress_role_sch2;
SET ROLE regress_role_sch2;
CREATE SCHEMA schema_sch2;
RESET ROLE;
DROP ROLE regress_role_sch2;

-- Should fail. Disallow CREATE SCHEMA if using a reserved name
CREATE SCHEMA pg_schema_sch2b;

-- Should fail. Disallow CREATE SCHEMA if already exists
CREATE SCHEMA schema_sch2c;
CREATE SCHEMA schema_sch2c;
DROP SCHEMA schema_sch2c;

-- Ensure CREATE SCHEMA uses current_user (and not necessarily session_user)
CREATE ROLE regress_role_sch3;
GRANT CREATE ON DATABASE regression TO regress_role_sch3;
SET ROLE regress_role_sch3;
CREATE SCHEMA schema_sch3;
SELECT schema_owner
FROM information_schema.schemata
WHERE schema_name = 'schema_sch3';
DROP SCHEMA schema_sch3;
RESET ROLE;
REVOKE CREATE ON DATABASE regression FROM regress_role_sch3;
DROP ROLE regress_role_sch3;

-- Should work. RENAME SCHEMA
CREATE SCHEMA schema_sch4;
ALTER SCHEMA schema_sch4 RENAME TO schema_sch4b;
DROP SCHEMA schema_sch4b;

-- ALTER SCHEMA ok for user created IN ROLE of one with CREATE DATABASE rights
CREATE ROLE regress_role_sch5;
GRANT CREATE ON DATABASE regression to regress_role_sch5;
CREATE ROLE regress_role_sch5b IN ROLE regress_role_sch5;
SET ROLE regress_role_sch5;
CREATE SCHEMA schema_sch5;
SET ROLE regress_role_sch5b;
ALTER SCHEMA schema_sch5 RENAME TO schema_sch5b;
ALTER SCHEMA schema_sch5b OWNER TO regress_role_sch5b;
DROP SCHEMA schema_sch5b;
RESET ROLE;
REVOKE CREATE ON DATABASE regression FROM regress_role_sch5;
SET ROLE regress_role_sch5;
RESET ROLE;
DROP ROLE regress_role_sch5b;
DROP ROLE regress_role_sch5;

-- Should work, REASSIGN OWNED objects to another OWNER
CREATE ROLE regress_role_sch6;
GRANT CREATE ON DATABASE regression to regress_role_sch6;
CREATE ROLE regress_role_sch6b;
SET ROLE regress_role_sch6;
CREATE SCHEMA schema_sch6;
RESET ROLE;
REVOKE CREATE ON DATABASE regression FROM regress_role_sch6;
REASSIGN OWNED BY regress_role_sch6 TO regress_role_sch6b;
SET ROLE regress_role_sch6b;
DROP SCHEMA schema_sch6;
RESET ROLE;
DROP ROLE regress_role_sch6b;
DROP ROLE regress_role_sch6;

-- Should fail. Shouldn't RENAME SCHEMA if invalid / already existing / etc.
CREATE SCHEMA schema_sch7;
CREATE SCHEMA schema_sch7b;
ALTER SCHEMA schema_sch7b RENAME TO schema_sch7;
ALTER SCHEMA schema_sch7b RENAME TO public;
ALTER SCHEMA schema_sch7b RENAME TO pg_asdf;
DROP SCHEMA schema_sch7;
DROP SCHEMA schema_sch7b;

-- Should fail. Shouldn't ALTER SCHEMA if not OWNER
CREATE SCHEMA schema_sch8;
CREATE ROLE regress_role_sch8;
SET ROLE regress_role_sch8;
ALTER SCHEMA schema_sch8 RENAME TO schema_sch8b;
ALTER SCHEMA schema_sch8 OWNER TO regress_role_sch8;
RESET ROLE;
DROP SCHEMA schema_sch8;
DROP ROLE regress_role_sch8;

-- Should work. Non-Owner with CREATE ON DATABASE priviledge can RENAME SCHEMA
CREATE ROLE regress_role_sch9;
GRANT CREATE ON DATABASE regression to regress_role_sch9;
SET ROLE regress_role_sch9;
CREATE SCHEMA schema_sch9;
RESET ROLE;
ALTER SCHEMA schema_sch9 RENAME TO schema_sch9b;
DROP SCHEMA schema_sch9b;
REVOKE CREATE ON DATABASE regression FROM regress_role_sch9;
DROP ROLE regress_role_sch9;

-- Should fail. OWNER without CREATE ON DATABASE can't ALTER OWNER SCHEMA
CREATE ROLE regress_role_sch10;
CREATE SCHEMA schema_sch10 AUTHORIZATION regress_role_sch10;
CREATE ROLE regress_role_sch10b;
GRANT regress_role_sch10b TO regress_role_sch10;
SET ROLE regress_role_sch10;
ALTER SCHEMA schema_sch10 RENAME TO schema_sch2;
ALTER SCHEMA schema_sch10 OWNER TO regress_role_sch10b;
RESET ROLE;
DROP SCHEMA schema_sch10;
REVOKE regress_role_sch10b FROM regress_role_sch10;
DROP ROLE regress_role_sch10b;
DROP ROLE regress_role_sch10;

-- Should work. Try to have multiple OWNERships for a ROLE
CREATE ROLE regress_role_sch11;
CREATE ROLE regress_role_sch11b;
CREATE SCHEMA schema_sch11;
GRANT CREATE ON SCHEMA schema_sch11 TO regress_role_sch11;
GRANT ALL ON SCHEMA schema_sch11 TO regress_role_sch11b;
ALTER SCHEMA schema_sch11 OWNER TO regress_role_sch11;
REVOKE CREATE ON SCHEMA schema_sch11 FROM regress_role_sch11;
REVOKE ALL ON SCHEMA schema_sch11 FROM regress_role_sch11b;
DROP SCHEMA schema_sch11;
DROP ROLE regress_role_sch11b;
DROP ROLE regress_role_sch11;

-- Change OWNER of SCHEMA
CREATE SCHEMA schema_sch12;
CREATE ROLE regress_role_sch12;
ALTER SCHEMA schema_sch12 OWNER TO regress_role_sch12;
DROP SCHEMA schema_sch12;
DROP ROLE regress_role_sch12;

-- Should fail. Can't change OWNER of SCHEMA if doesn't exist/invalid name/etc.
ALTER SCHEMA schema_sch13 RENAME TO schema_sch13;
CREATE ROLE regress_role_sch13;
ALTER SCHEMA schema_sch13 OWNER TO regress_role_sch13;
DROP ROLE regress_role_sch13;
