.mode list
.headers off

SET temp_directory='/tmp/duckdb_sirene';
SET memory_limit='4GB';
PRAGMA enable_progress_bar;

.print ===========================================
.print == NAFRev2
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> importing NAFRev2...
BEGIN TRANSACTION;

CREATE OR REPLACE TABLE sirene_nafrev2 (
    code        VARCHAR,
    description VARCHAR
);
INSERT INTO sirene_nafrev2 FROM read_csv('./downloaded/sirene/NAFRev2.csv', ignore_errors=true);

COMMIT;
SELECT format('[{:.1f}s] ✓ NAFRev2 imported', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print

.print ===========================================
.print == Entreprises
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> importing sirene_entreprises...
BEGIN TRANSACTION;

CREATE OR REPLACE TABLE sirene_entreprises AS
    SELECT
        siren,
        denominationUniteLegale
    FROM read_csv('./downloaded/sirene/StockUniteLegale_utf8.csv', ignore_errors=true)
    WHERE
        unitePurgeeUniteLegale  IS NOT TRUE
        AND categorieJuridiqueUniteLegale != 1000
        AND etatAdministratifUniteLegale  != 'C'
        AND statutDiffusionUniteLegale     = 'O'
;

COMMIT;
.print >>> indexing sirene_entreprises...
CREATE INDEX idx_sirene_entreprises_siren ON sirene_entreprises (siren);
SELECT format('[{:.1f}s] ✓ sirene_entreprises imported + indexed', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print

.print ===========================================
.print == Etablissements
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> importing sirene_etablissements...
BEGIN TRANSACTION;

CREATE OR REPLACE TABLE sirene_etablissements AS
    SELECT
        e.siren,
        e.nic,
        e.siret,
        e.dateCreationEtablissement,
        e.trancheEffectifsEtablissement,
        NULL::BIGINT                                    AS minNbEffectifsEtablissement,
        e.anneeEffectifsEtablissement,
        e.activitePrincipaleRegistreMetiersEtablissement,
        e.dateDernierTraitementEtablissement,
        e.etablissementSiege,
        e.nombrePeriodesEtablissement,
        e.complementAdresseEtablissement,
        e.numeroVoieEtablissement,
        e.indiceRepetitionEtablissement,
        e.dernierNumeroVoieEtablissement,
        e.typeVoieEtablissement,
        e.libelleVoieEtablissement,
        e.codePostalEtablissement,
        e.libelleCommuneEtablissement,
        e.libelleCommuneEtrangerEtablissement,
        e.distributionSpecialeEtablissement,
        e.codeCommuneEtablissement,
        substring(e.codeCommuneEtablissement, 1, 2)     AS departementEtablissement,
        e.codePaysEtrangerEtablissement,
        e.libellePaysEtrangerEtablissement,
        e.identifiantAdresseEtablissement,
        e.coordonneeLambertAbscisseEtablissement,
        e.coordonneeLambertOrdonneeEtablissement,
        e.dateDebut,
        e.enseigne1Etablissement,
        e.enseigne2Etablissement,
        e.enseigne3Etablissement,
        e.denominationUsuelleEtablissement,
        e.activitePrincipaleEtablissement,
        e.nomenclatureActivitePrincipaleEtablissement,
        NULL::BIGINT                                    AS geonames_cityid,
        NULL::VARCHAR                                   AS geonames_city,
        g.x_longitude::DOUBLE                           AS longitude,
        g.y_latitude::DOUBLE                            AS latitude
    FROM read_csv('./downloaded/sirene/StockEtablissement_utf8.csv') e
    LEFT JOIN read_csv('./downloaded/sirene/GeolocalisationEtablissement_Sirene_pour_etudes_statistiques_utf8.csv') g
        ON g.siret = e.siret
    WHERE
        e.statutDiffusionEtablissement = 'O'
        AND e.etatAdministratifEtablissement = 'A'
;

COMMIT;
SELECT format('[{:.1f}s] ✓ sirene_etablissements imported', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print

.print ===========================================
.print == Fixes
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> updating effectifs...
BEGIN TRANSACTION;

UPDATE sirene_etablissements
SET minNbEffectifsEtablissement = CASE trancheEffectifsEtablissement
    WHEN 'NN' THEN 0
    WHEN '00' THEN 0
    WHEN '01' THEN 1
    WHEN '02' THEN 3
    WHEN '03' THEN 6
    WHEN '11' THEN 10
    WHEN '12' THEN 20
    WHEN '21' THEN 50
    WHEN '22' THEN 100
    WHEN '31' THEN 200
    WHEN '32' THEN 250
    WHEN '41' THEN 500
    WHEN '42' THEN 1000
    WHEN '51' THEN 2000
    WHEN '52' THEN 5000
    WHEN '53' THEN 10000
    ELSE minNbEffectifsEtablissement
END
WHERE trancheEffectifsEtablissement IN ('NN','00','01','02','03','11','12','21','22','31','32','41','42','51','52','53')
;

COMMIT;
SELECT format('[{:.1f}s] ✓ effectifs updated', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print

SET VARIABLE tstart = epoch_ms(now());
.print >>> updating geonames city...
BEGIN TRANSACTION;

UPDATE sirene_etablissements ets
SET
    geonames_cityid = g.city_id,
    geonames_city   = g.city_name
FROM geonames_allentries g
WHERE
    g.country_code = 'FR'
    AND g.feature_code = 'ADM4'
    AND g.admin4_code = CASE
        WHEN ets.codeCommuneEtablissement BETWEEN '75101' AND '75120' THEN '75056'
        WHEN ets.codeCommuneEtablissement BETWEEN '13201' AND '13216' THEN '13055'
        WHEN ets.codeCommuneEtablissement BETWEEN '69381' AND '69389' THEN '69123'
        ELSE ets.codeCommuneEtablissement
    END
;

COMMIT;
SELECT format('[{:.1f}s] ✓ geonames city updated', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print


.print ===========================================
.print == Vue d'export
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> creating view v_sirene_export...

CREATE OR REPLACE VIEW v_sirene_export AS
    SELECT
        e.siren,
        e.siret,
        COALESCE(
            NULLIF(TRIM(e.denominationUsuelleEtablissement), ''),
            NULLIF(TRIM(e.enseigne1Etablissement),           ''),
            NULLIF(TRIM(ent.denominationUniteLegale),        ''),
            e.siret
        )                                        AS name,
        COALESCE(ent.denominationUniteLegale, '') AS legal_name,
        e.activitePrincipaleEtablissement         AS ape,
        sc.section_id,
        sc.division_id,
        sc.groupe_id,
        sc.classe_id,
        e.etablissementSiege                      AS is_siege,
        e.dateCreationEtablissement               AS date_creation,
        e.minNbEffectifsEtablissement             AS nb_effectifs_min,
        e.departementEtablissement                AS dept,
        e.codePostalEtablissement                 AS code_postal,
        e.libelleCommuneEtablissement             AS commune,
        e.codeCommuneEtablissement                AS code_commune,
        TRIM(CONCAT_WS(' ',
            NULLIF(TRIM(e.numeroVoieEtablissement),  ''),
            NULLIF(TRIM(e.typeVoieEtablissement),    ''),
            NULLIF(TRIM(e.libelleVoieEtablissement), '')
        ))                                        AS adresse,
        e.geonames_cityid,
        e.geonames_city,
        ROUND(e.latitude::DOUBLE,  5)             AS latitude,
        ROUND(e.longitude::DOUBLE, 5)             AS longitude
    FROM sirene_etablissements e
    LEFT JOIN  sirene_entreprises  ent ON ent.siren          = e.siren
    INNER JOIN nafrev2_sous_classes sc  ON sc.sous_classe_id  = e.activitePrincipaleEtablissement
;

SELECT format('[{:.1f}s] ✓ v_sirene_export view created', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print

.print ===========================================
.print == Export observable etablissements (partitioned by name prefix)
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> exporting observable etab parquets by name prefix...

SET threads=1;
COPY (
    SELECT
        latitude,
        longitude,
        name,
        adresse,
        siret,
        nb_effectifs_min,
        is_siege,
        CAST(date_creation AS VARCHAR) AS date_creation,
        legal_name,
        dept,
        ape,
        LEFT(LOWER(TRIM(COALESCE(name, ''))), 2) AS pfx
    FROM v_sirene_export
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL
) TO './dataset/sirene/observable/etab/'
(FORMAT PARQUET, PARTITION_BY (pfx));
RESET threads;

SELECT format('[{:.1f}s] ✓ observable etab parquets exported', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print

.print ===========================================
.print == Export etab global stats
.print ===========================================
SET VARIABLE tstart = epoch_ms(now());
.print >>> exporting etab-stats.parquet...

COPY (
    SELECT
        COUNT(*)                          AS nb_etablissements,
        COUNT(DISTINCT LEFT(siret, 9))    AS nb_siren
    FROM v_sirene_export
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL
) TO './dataset/sirene/observable/etab-stats.parquet' (FORMAT PARQUET);

SELECT format('[{:.1f}s] ✓ etab-stats.parquet exported', (epoch_ms(now()) - getvariable('tstart')) / 1000.0);
.print
