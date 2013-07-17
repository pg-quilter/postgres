---
--- test creation of SERIAL column
---

CREATE TABLE serialTest (f1 text, f2 serial);

INSERT INTO serialTest VALUES ('foo');
INSERT INTO serialTest VALUES ('bar');
INSERT INTO serialTest VALUES ('force', 100);
INSERT INTO serialTest VALUES ('wrong', NULL);

SELECT * FROM serialTest;

-- test smallserial / bigserial
CREATE TABLE serialTest2 (f1 text, f2 serial, f3 smallserial, f4 serial2,
  f5 bigserial, f6 serial8);

INSERT INTO serialTest2 (f1)
  VALUES ('test_defaults');

INSERT INTO serialTest2 (f1, f2, f3, f4, f5, f6)
  VALUES ('test_max_vals', 2147483647, 32767, 32767, 9223372036854775807,
          9223372036854775807),
         ('test_min_vals', -2147483648, -32768, -32768, -9223372036854775808,
          -9223372036854775808);

-- All these INSERTs should fail:
INSERT INTO serialTest2 (f1, f3)
  VALUES ('bogus', -32769);

INSERT INTO serialTest2 (f1, f4)
  VALUES ('bogus', -32769);

INSERT INTO serialTest2 (f1, f3)
  VALUES ('bogus', 32768);

INSERT INTO serialTest2 (f1, f4)
  VALUES ('bogus', 32768);

INSERT INTO serialTest2 (f1, f5)
  VALUES ('bogus', -9223372036854775809);

INSERT INTO serialTest2 (f1, f6)
  VALUES ('bogus', -9223372036854775809);

INSERT INTO serialTest2 (f1, f5)
  VALUES ('bogus', 9223372036854775808);

INSERT INTO serialTest2 (f1, f6)
  VALUES ('bogus', 9223372036854775808);

SELECT * FROM serialTest2 ORDER BY f2 ASC;

SELECT nextval('serialTest2_f2_seq');
SELECT nextval('serialTest2_f3_seq');
SELECT nextval('serialTest2_f4_seq');
SELECT nextval('serialTest2_f5_seq');
SELECT nextval('serialTest2_f6_seq');

-- basic sequence operations using both text and oid references
CREATE SEQUENCE sequence_test;

SELECT nextval('sequence_test'::text);
SELECT nextval('sequence_test'::regclass);
SELECT currval('sequence_test'::text);
SELECT currval('sequence_test'::regclass);
SELECT setval('sequence_test'::text, 32);
SELECT nextval('sequence_test'::regclass);
SELECT setval('sequence_test'::text, 99, false);
SELECT nextval('sequence_test'::regclass);
SELECT setval('sequence_test'::regclass, 32);
SELECT nextval('sequence_test'::text);
SELECT setval('sequence_test'::regclass, 99, false);
SELECT nextval('sequence_test'::text);

DROP SEQUENCE sequence_test;

-- renaming sequences
CREATE SEQUENCE foo_seq;
ALTER TABLE foo_seq RENAME TO foo_seq_new;
SELECT * FROM foo_seq_new;
SELECT nextval('foo_seq_new');
SELECT nextval('foo_seq_new');
SELECT * FROM foo_seq_new;
DROP SEQUENCE foo_seq_new;

-- renaming serial sequences
ALTER TABLE serialtest_f2_seq RENAME TO serialtest_f2_foo;
INSERT INTO serialTest VALUES ('more');
SELECT * FROM serialTest;

--
-- Check dependencies of serial and ordinary sequences
--
CREATE TEMP SEQUENCE myseq2;
CREATE TEMP SEQUENCE myseq3;
CREATE TEMP TABLE t1 (
  f1 serial,
  f2 int DEFAULT nextval('myseq2'),
  f3 int DEFAULT nextval('myseq3'::text)
);
-- Both drops should fail, but with different error messages:
DROP SEQUENCE t1_f1_seq;
DROP SEQUENCE myseq2;
-- This however will work:
DROP SEQUENCE myseq3;
DROP TABLE t1;
-- Fails because no longer existent:
DROP SEQUENCE t1_f1_seq;
-- Now OK:
DROP SEQUENCE myseq2;

--
-- Alter sequence
--

ALTER SEQUENCE IF EXISTS sequence_test2 RESTART WITH 24
	 INCREMENT BY 4 MAXVALUE 36 MINVALUE 5 CYCLE;

CREATE SEQUENCE sequence_test2 START WITH 32;

SELECT nextval('sequence_test2');

ALTER SEQUENCE sequence_test2 RESTART WITH 24
	 INCREMENT BY 4 MAXVALUE 36 MINVALUE 5 CYCLE;
SELECT nextval('sequence_test2');
SELECT nextval('sequence_test2');
SELECT nextval('sequence_test2');
SELECT nextval('sequence_test2');
SELECT nextval('sequence_test2');

ALTER SEQUENCE sequence_test2 RESTART;

SELECT nextval('sequence_test2');
SELECT nextval('sequence_test2');
SELECT nextval('sequence_test2');

-- Information schema
SELECT * FROM information_schema.sequences WHERE sequence_name IN
  ('sequence_test2', 'serialtest2_f2_seq', 'serialtest2_f3_seq',
   'serialtest2_f4_seq', 'serialtest2_f5_seq', 'serialtest2_f6_seq')
  ORDER BY sequence_name ASC;

-- Test comments
COMMENT ON SEQUENCE asdf IS 'won''t work';
COMMENT ON SEQUENCE sequence_test2 IS 'will work';
COMMENT ON SEQUENCE sequence_test2 IS NULL;

-- Test lastval()
CREATE SEQUENCE seq;
SELECT nextval('seq');
SELECT lastval();
SELECT setval('seq', 99);
SELECT lastval();

CREATE SEQUENCE seq2;
SELECT nextval('seq2');
SELECT lastval();

DROP SEQUENCE seq2;
-- should fail
SELECT lastval();

CREATE USER seq_user;

BEGIN;
SET LOCAL SESSION AUTHORIZATION seq_user;
CREATE SEQUENCE seq3;
SELECT nextval('seq3');
REVOKE ALL ON seq3 FROM seq_user;
SELECT lastval();
ROLLBACK;

-- Sequences should get wiped out as well:
DROP TABLE serialTest, serialTest2;

-- Make sure sequences are gone:
SELECT * FROM information_schema.sequences WHERE sequence_name IN
  ('sequence_test2', 'serialtest2_f2_seq', 'serialtest2_f3_seq',
   'serialtest2_f4_seq', 'serialtest2_f5_seq', 'serialtest2_f6_seq')
  ORDER BY sequence_name ASC;

DROP USER seq_user;
DROP SEQUENCE seq;

-- Test SEQUENCE tied to a field
CREATE TABLE tbl_seq1 (f1 bigint, f2 bigint);
CREATE SEQUENCE seq4 OWNED BY tbl_seq1.f1;
ALTER TABLE tbl_seq1 DROP COLUMN f1;
DROP TABLE tbl_seq1;

-- Should fail since seq5 shouldn't exist
DROP SEQUENCE seq5;

-- Should fail, unlogged sequences are currently not supported
CREATE TABLE tbl_seq2 (f1 bigint, f2 bigint);
CREATE UNLOGGED SEQUENCE seq6 OWNED BY tbl_seq2.f1;
DROP TABLE tbl_seq2;

-- non-OWNER should not be allowed to access SEQUENCE
CREATE SEQUENCE seq7;
SELECT nextval('seq7');
CREATE ROLE regress_role_seq1;
SET ROLE regress_role_seq1;
SELECT nextval('seq7');
SELECT currval('seq7');
SELECT setval('seq7', 10);
ALTER SEQUENCE seq7 OWNED BY NONE;
SELECT * FROM seq7;
RESET ROLE;
DROP ROLE regress_role_seq1;
DROP SEQUENCE seq7;

-- non-OWNER when allowed to create SEQUENCE on table, should by OWNED by tbl owner
CREATE USER regress_role_seq2;
SET ROLE regress_role_seq2;
CREATE TABLE tbl_seq2 (f1 bigint);
RESET ROLE;
ALTER TABLE tbl_seq2 ADD COLUMN f2 bigserial;
SET ROLE regress_role_seq2;
DROP TABLE tbl_seq2;
RESET ROLE;
DROP ROLE regress_role_seq2;

-- Should fail, Currval not yet defined in session
CREATE SEQUENCE seq8;
SELECT currval('seq8');
DROP SEQUENCE seq8;

-- Setval should work with valid values
CREATE SEQUENCE seq9;
SELECT setval('seq9', 10);
SELECT setval('seq9', 20, true);
SELECT setval('seq9', 30, false);
DROP SEQUENCE seq9;

-- Should fail, setval beyond limits
CREATE SEQUENCE seq10 MINVALUE 20 MAXVALUE 30;
SELECT setval('seq10', 31);
SELECT setval('seq10', 19);
DROP SEQUENCE seq10;

-- Should fail, trying a SEQUENCE function on a valid but non-SEQUENCE object
CREATE TABLE tbl_seq3 (f1 bigint);
SELECT nextval('tbl_seq3');
DROP TABLE tbl_seq3;

-- Should fail, crosscheck min/max
CREATE SEQUENCE seq11 MINVALUE 40 MAXVALUE 30;
CREATE SEQUENCE seq11 MINVALUE 20 MAXVALUE 20;
CREATE SEQUENCE seq11 MINVALUE 40 MAXVALUE 20 INCREMENT BY -1;

-- Should fail, crosscheck START with min/max
CREATE SEQUENCE seq12 START 29 MINVALUE 30 MAXVALUE 40;
CREATE SEQUENCE seq12 START -41 MINVALUE -40 MAXVALUE -30 INCREMENT BY -1;
CREATE SEQUENCE seq12 START 41 MINVALUE 30 MAXVALUE 40;
CREATE SEQUENCE seq12 START -29 MINVALUE -40 MAXVALUE -30 INCREMENT BY -1;

-- Should work, ensure valid START works with valid min/max
CREATE SEQUENCE seq13 START 35 MINVALUE 30 MAXVALUE 40;
DROP SEQUENCE seq13;
CREATE SEQUENCE seq13 START -35 MINVALUE -40 MAXVALUE -30 INCREMENT BY -1;
DROP SEQUENCE seq13;

-- Should fail, crosscheck RESTART with min/max
CREATE SEQUENCE seq14 RESTART 29 MINVALUE 30 MAXVALUE 40;
CREATE SEQUENCE seq14 RESTART -41 MINVALUE -40 MAXVALUE -30 INCREMENT BY -1;
CREATE SEQUENCE seq14 RESTART 41 MINVALUE 30 MAXVALUE 40;
CREATE SEQUENCE seq14 RESTART -29 MINVALUE -40 MAXVALUE -30 INCREMENT BY -1;

-- Should work, ensure valid RESTART works with valid min/max
CREATE SEQUENCE seq15 RESTART 35 MINVALUE 30 MAXVALUE 40;
DROP SEQUENCE seq15;
CREATE SEQUENCE seq15 RESTART -35 MINVALUE -40 MAXVALUE -30 INCREMENT BY -1;
DROP SEQUENCE seq15;

-- Should fail, Invalid OWNED BY option
CREATE TABLE tbl_seq4 (f1 bigint);
CREATE SEQUENCE seq16 OWNED BY asdf;
CREATE SEQUENCE seq16 OWNED BY tbl_seq4;
CREATE SEQUENCE seq16 OWNED BY tbl_seq4.asdf;
CREATE SEQUENCE seq16;
CREATE SEQUENCE seq17 OWNED BY seq16.asdf;
DROP SEQUENCE seq16;
DROP TABLE tbl_seq4;

-- Should fail, ensure table / sequence have same owner
CREATE TABLE tbl_seq5 (f1 bigint);
CREATE USER regress_role_seq3;
SET ROLE regress_role_seq3;
CREATE SEQUENCE seq18;
ALTER SEQUENCE seq18 OWNED BY tbl_seq5.f1;
DROP SEQUENCE seq18;
RESET ROLE;
DROP ROLE regress_role_seq3;
DROP TABLE tbl_seq5;

-- Should fail, ensure table / sequence have same schema
CREATE TABLE tbl_seq6 (f1 bigint);
CREATE SCHEMA schema_seq1;
CREATE SEQUENCE schema_seq1.seq5;
ALTER SEQUENCE schema_seq1.seq5 OWNED BY tbl_seq6.f1;
DROP SEQUENCE schema_seq1.seq5;
DROP SCHEMA schema_seq1;
DROP TABLE tbl_seq6;

-- Should fail, INCREMENT BY cannot be 0
CREATE SEQUENCE seq19 INCREMENT BY 0;

-- Check MAXVALUE in ALTER SEQUENCE
CREATE SEQUENCE seq20 MINVALUE 1 MAXVALUE 2;
ALTER SEQUENCE seq20 MINVALUE 0;
SELECT nextval('seq20');
SELECT nextval('seq20');
SELECT nextval('seq20');
ALTER SEQUENCE seq20 MAXVALUE 3;
SELECT nextval('seq20');
DROP SEQUENCE seq20;

-- Check MINVALUE in ALTER SEQUENCE
CREATE SEQUENCE seq21 MINVALUE 1 MAXVALUE 2 INCREMENT -1;
SELECT nextval('seq21');
SELECT nextval('seq21');
SELECT nextval('seq21');
ALTER SEQUENCE seq21 MINVALUE 0;
SELECT nextval('seq21');
DROP SEQUENCE seq21;

-- Should fail, Should not allow conflicting / Redundant options
CREATE SEQUENCE seq22;
ALTER SEQUENCE seq22 MAXVALUE 100 NO MAXVALUE;
ALTER SEQUENCE seq22 MINVALUE 100 NO MINVALUE;
ALTER SEQUENCE seq22 INCREMENT BY 1 INCREMENT BY -1;
ALTER SEQUENCE seq22 START 1 START 2;
ALTER SEQUENCE seq22 RESTART 1 RESTART 2;
ALTER SEQUENCE seq22 CACHE 1 CACHE 2;
ALTER SEQUENCE seq22 CYCLE NO CYCLE;
ALTER SEQUENCE seq22 OWNED BY NONE OWNED BY regression;
ALTER SEQUENCE seq22 asdf;
DROP SEQUENCE seq22;

-- Check NO MINVALUE starts with 1
CREATE SEQUENCE seq23 NO MINVALUE;
ALTER SEQUENCE seq23 MINVALUE 1;
SELECT nextval('seq23');
DROP SEQUENCE seq23;

-- Should work. Check that OWNED BY works as expected
CREATE TABLE tbl_seq7 (f1 bigint);
CREATE SEQUENCE seq24 OWNED BY tbl_seq7.f2;
CREATE SEQUENCE seq24 OWNED BY tbl_seq7.f1;
ALTER SEQUENCE seq24 OWNED BY NONE;
DROP TABLE tbl_seq7;
DROP SEQUENCE seq24;

-- Should fail, Invalid CACHE value
CREATE SEQUENCE seq25 CACHE 0;

-- Ensure correct MAXVALUE for descending sequence. Also check valid CACHE value
CREATE SEQUENCE seq27 INCREMENT -1 MAXVALUE -2 CACHE 2;
SELECT nextval('seq27');
SELECT nextval('seq27');
DROP SEQUENCE seq27;

-- Should stop incr when INCREMENT 1, CACHE > 1, MAXVALUE < 0, near MAXVALUE
CREATE SEQUENCE seq28 INCREMENT 1 CACHE 3 MINVALUE -2 MAXVALUE -1;
SELECT nextval('seq28');
SELECT nextval('seq28');
SELECT nextval('seq28');
DROP SEQUENCE seq28;

-- Should stop decr when INCREMENT -1, CACHE > 1, MINVALUE > 0, near MINVALUE
CREATE SEQUENCE seq29 INCREMENT -1 CACHE 3 MINVALUE 1 MAXVALUE 2;
SELECT nextval('seq29');
SELECT nextval('seq29');
SELECT nextval('seq29');
DROP SEQUENCE seq29;

-- Should cycle when CYCLE is SET
CREATE SEQUENCE seq30 CYCLE INCREMENT -1 MINVALUE 1 MAXVALUE 2;
SELECT nextval('seq30');
SELECT nextval('seq30');
SELECT nextval('seq30');
DROP SEQUENCE seq30;
