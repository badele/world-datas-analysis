.mode list
.headers off

SET temp_directory='/tmp/duckdb_etab';
SET memory_limit='2GB';
PRAGMA enable_progress_bar;

.print ===========================================
.print == Generate etab prefix parquets from APE parquets
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> reading APE parquets, partitioning by name prefix (spilling to /tmp/duckdb_etab)...

COPY (
    SELECT
        siret,
        name,
        legal_name,
        adresse,
        nb_effectifs_min,
        is_siege,
        date_creation,
        dept,
        latitude,
        longitude,
        regexp_extract(filename, 'ape=([^/\\]+)[/\\]', 1) AS ape,
        LEFT(LOWER(TRIM(COALESCE(name, ''))), 3) AS pfx
    FROM read_parquet('./dataset/sirene/observable/ape=*/data_0.parquet',
                      hive_partitioning=false,
                      filename=true)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL
) TO './dataset/sirene/observable/etab/'
(FORMAT PARQUET, PARTITION_BY (pfx));

SELECT format('[{:.1f}s] ✓ etab prefix parquets generated', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
