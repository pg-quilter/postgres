/* contrib/pg_freespacemap/pg_freespacemap--1.1.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_freespacemap" to load this file. \quit

-- Register the C function.
CREATE FUNCTION pg_freespace(regclass, bigint)
RETURNS int2
AS 'MODULE_PATHNAME', 'pg_freespace'
LANGUAGE C STRICT;

CREATE FUNCTION pg_is_all_visible(regclass, bigint)
RETURNS bool
AS 'MODULE_PATHNAME', 'pg_is_all_visible'
LANGUAGE C STRICT;

-- pg_freespace shows the recorded space avail at each block in a relation
CREATE FUNCTION
  pg_freespace(rel regclass, blkno OUT bigint, avail OUT int2)
RETURNS SETOF RECORD
AS $$
  SELECT blkno, pg_freespace($1, blkno) AS avail
  FROM generate_series(0, pg_relation_size($1) / current_setting('block_size')::bigint - 1) AS blkno;
$$
LANGUAGE SQL;

CREATE FUNCTION
  pg_freespace_with_vminfo(rel regclass, blkno OUT bigint, avail OUT int2, is_all_visible OUT boolean)
RETURNS SETOF RECORD
AS $$
  SELECT blkno, pg_freespace($1, blkno) AS avail, pg_is_all_visible($1, blkno) as is_all_visible
  FROM generate_series(0, pg_relation_size($1) / current_setting('block_size')::bigint - 1) AS blkno;
$$
LANGUAGE SQL;



-- Don't want these to be available to public.
REVOKE ALL ON FUNCTION pg_freespace(regclass, bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION pg_freespace(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION pg_freespace_with_vminfo(regclass) FROM PUBLIC;
