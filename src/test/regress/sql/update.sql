--
-- UPDATE syntax tests
--

CREATE TABLE update_test (
    a   INT DEFAULT 10,
    b   INT,
    c   TEXT
);

INSERT INTO update_test VALUES (5, 10, 'foo');
INSERT INTO update_test(b, a) VALUES (15, 10);

SELECT * FROM update_test;

UPDATE update_test SET a = DEFAULT, b = DEFAULT;

SELECT * FROM update_test;

-- aliases for the UPDATE target table
UPDATE update_test AS t SET b = 10 WHERE t.a = 10;

SELECT * FROM update_test;

UPDATE update_test t SET b = t.b + 10 WHERE t.a = 10;

SELECT * FROM update_test;

--
-- Test VALUES in FROM
--

UPDATE update_test SET a=v.i FROM (VALUES(100, 20)) AS v(i, j)
  WHERE update_test.b = v.j;

SELECT * FROM update_test;

--
-- Test multiple-set-clause syntax
--

UPDATE update_test SET (c,b,a) = ('bugle', b+11, DEFAULT) WHERE c = 'foo';
SELECT * FROM update_test;
UPDATE update_test SET (c,b) = ('car', a+b), a = a + 1 WHERE a = 10;
SELECT * FROM update_test;
-- fail, multi assignment to same column:
UPDATE update_test SET (c,b) = ('car', a+b), b = a + 1 WHERE a = 10;

-- XXX this should work, but doesn't yet:
UPDATE update_test SET (a,b) = (select a,b FROM update_test where c = 'foo')
  WHERE a = 10;

-- if an alias for the target table is specified, don't allow references
-- to the original table name
UPDATE update_test AS t SET b = update_test.b + 10 WHERE t.a = 10;

-- Make sure that we can update to a TOASTed value.
UPDATE update_test SET c = repeat('x', 10000) WHERE c = 'car';
SELECT a, b, char_length(c) FROM update_test;

DROP TABLE update_test;


--
-- Test to update continuos and non continuos columns
--

DROP TABLE IF EXISTS update_test;
CREATE TABLE update_test (
		bser bigserial,
		bln boolean,
		ename VARCHAR(25),
		perf_f float(8),
		grade CHAR,
		dept CHAR(5) NOT NULL,
		dob DATE,
		idnum INT,
		addr VARCHAR(30) NOT NULL,
		destn CHAR(6),
		Gend CHAR,
		samba BIGINT,
		hgt float,
		ctime TIME
);

INSERT INTO update_test VALUES (
		nextval('update_test_bser_seq'::regclass),
		TRUE,
		'Test',
		7.169,
		'B',
		'CSD',
		'2000-01-01',
		520,
		'road2,
		streeeeet2,
		city2',
		'dcy2',
		'M',
		12000,
		50.4,
		'00:00:00.0'
);

SELECT * from update_test;

-- update first column
UPDATE update_test SET bser = bser - 1 + 1;

-- update middle column
UPDATE update_test SET perf_f = 8.9;

-- update last column
UPDATE update_test SET ctime = '00:00:00.1';

-- update 3 continuos columns
UPDATE update_test SET destn = 'dcy2', samba = 0 WHERE Gend = 'M' and dept = 'CSD';

-- update two non continuos columns
UPDATE update_test SET destn = 'moved', samba = 0;
UPDATE update_test SET bln = FALSE, hgt = 10.1;

-- update causing some column alignment difference
UPDATE update_test SET ename = 'Tes';
UPDATE update_test SET dept = 'Test';

SELECT * from update_test;
DROP TABLE update_test;
