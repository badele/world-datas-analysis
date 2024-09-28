-------------------------------------------------------------------------------
-- Active PSQL DuckDB FDW extension
-------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT
            1
        FROM
            pg_extension
        WHERE
            extname = 'duckdb_fdw') THEN
    CREATE EXTENSION duckdb_fdw;
END IF;
END
$$;

-------------------------------------------------------------------------------
-- enable duckdb server
-------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT
            1
        FROM
            pg_foreign_server
        WHERE
            srvname = 'duckdb_svr') THEN
    CREATE SERVER duckdb_svr FOREIGN DATA WRAPPER duckdb_fdw OPTIONS (
        DATABASE ':memory:'
    );
END IF;
END
$$;

\i './importer/init_commons.sql'
