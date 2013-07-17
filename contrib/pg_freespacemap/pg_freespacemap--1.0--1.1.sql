/* contrib/pg_freespacemap/pg_freespacemap--1.0--1.1.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "ALTER EXTENSION pg_freespacemap UPDATE TO '1.1'" to load this file. \quit

CREATE FUNCTION pg_is_all_visible(regclass, bigint)
RETURNS bool
AS 'MODULE_PATHNAME', 'pg_is_all_visible'
LANGUAGE C STRICT;

CREATE FUNCTION
  pg_freespace_with_vminfo(rel regclass, blkno OUT bigint, avail OUT int2, is_all_visible OUT boolean)
RETURNS SETOF RECORD
AS $$
  SELECT blkno, pg_freespace($1, blkno) AS avail, pg_is_all_visible($1, blkno) as is_all_visible
  FROM generate_series(0, pg_relation_size($1) / current_setting('block_size')::bigint - 1) AS blkno;
$$
LANGUAGE SQL;

-- Don't want these to be available to public.
REVOKE ALL ON FUNCTION pg_freespace_with_vminfo(regclass) FROM PUBLIC;
