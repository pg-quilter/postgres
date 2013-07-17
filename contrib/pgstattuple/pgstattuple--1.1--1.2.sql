/* contrib/pgstattuple/pgstattuple--1.1--1.2.sql */

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pgstattuple UPDATE TO '1.2'" to load this file. \quit

DROP FUNCTION pgstattuple(text);
CREATE OR REPLACE FUNCTION pgstattuple(IN relname text,
    OUT table_len BIGINT,		-- physical table length in bytes
    OUT tuple_count BIGINT,		-- number of live tuples
    OUT tuple_len BIGINT,		-- total tuples length in bytes
    OUT tuple_percent FLOAT8,		-- live tuples in %
    OUT dead_tuple_count BIGINT,	-- number of dead tuples
    OUT dead_tuple_len BIGINT,		-- total dead tuples length in bytes
    OUT dead_tuple_percent FLOAT8,	-- dead tuples in %
    OUT free_space BIGINT,		-- free space in bytes
    OUT free_percent FLOAT8,		-- free space in %
    OUT all_visible_percent FLOAT8)		-- all visible blocks in %
AS 'MODULE_PATHNAME', 'pgstattuple'
LANGUAGE C STRICT;

DROP FUNCTION pgstattuple(oid);
CREATE OR REPLACE FUNCTION pgstattuple(IN reloid oid,
    OUT table_len BIGINT,		-- physical table length in bytes
    OUT tuple_count BIGINT,		-- number of live tuples
    OUT tuple_len BIGINT,		-- total tuples length in bytes
    OUT tuple_percent FLOAT8,		-- live tuples in %
    OUT dead_tuple_count BIGINT,	-- number of dead tuples
    OUT dead_tuple_len BIGINT,		-- total dead tuples length in bytes
    OUT dead_tuple_percent FLOAT8,	-- dead tuples in %
    OUT free_space BIGINT,		-- free space in bytes
    OUT free_percent FLOAT8,		-- free space in %
    OUT all_visible_percent FLOAT8)		-- all visible blocks in %
AS 'MODULE_PATHNAME', 'pgstattuplebyid'
LANGUAGE C STRICT;
