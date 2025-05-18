BEGIN;

-- disable pager
\pset pager off

\i './importer/init_psql.sql';

--------------------------------------------------------------------------------
-- NAF rev2
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_sirene_nafrev2 CASCADE;
CREATE FOREIGN TABLE duckdb_sirene_nafrev2 (
    code TEXT,
    description TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/sirene/nafrev2.parquet")'
);
;

--------------------------------------------------------------------------------
-- Enterprises
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_sirene_entreprises CASCADE;
CREATE FOREIGN TABLE duckdb_sirene_entreprises (
    siren TEXT,
    dateCreationUniteLegale DATE,
    sigleUniteLegale TEXT,
    identifiantAssociationUniteLegale TEXT,
    trancheEffectifsUniteLegale TEXT,
    minNbEffectifsUniteLegale BIGINT,
    anneeEffectifsUniteLegale BIGINT,
    dateDernierTraitementUniteLegale DATE,
    nombrePeriodesUniteLegale BIGINT,
    categorieEntreprise TEXT,
    anneeCategorieEntreprise BIGINT,
    dateDebut DATE,
    denominationUniteLegale TEXT,
    denominationUsuelle1UniteLegale TEXT,
    denominationUsuelle2UniteLegale TEXT,
    denominationUsuelle3UniteLegale TEXT,
    activitePrincipaleUniteLegale TEXT,
    nomenclatureActivitePrincipaleUniteLegale TEXT,
    nicSiegeUniteLegale TEXT,
    economieSocialeSolidaireUniteLegale TEXT
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/sirene/entreprises.parquet")'
)
;

--------------------------------------------------------------------------------
-- Etablissements
--------------------------------------------------------------------------------
DROP FOREIGN TABLE IF EXISTS duckdb_sirene_etablissements CASCADE;
CREATE FOREIGN TABLE duckdb_sirene_etablissements (
    siren VARCHAR,
    nic VARCHAR,
    siret VARCHAR,
    dateCreationEtablissement DATE,
    trancheEffectifsEtablissement VARCHAR,
    minNbEffectifsEtablissement BIGINT,
    anneeEffectifsEtablissement BIGINT,
    activitePrincipaleRegistreMetiersEtablissement VARCHAR,
    dateDernierTraitementEtablissement TIMESTAMP,
    etablissementSiege BOOLEAN,
    nombrePeriodesEtablissement BIGINT,
    complementAdresseEtablissement VARCHAR,
    numeroVoieEtablissement VARCHAR,
    indiceRepetitionEtablissement VARCHAR,
    dernierNumeroVoieEtablissement VARCHAR,
    typeVoieEtablissement VARCHAR,
    libelleVoieEtablissement VARCHAR,
    codePostalEtablissement VARCHAR,
    departementEtablissement VARCHAR,
    libelleCommuneEtablissement VARCHAR,
    libelleCommuneEtrangerEtablissement VARCHAR,
    distributionSpecialeEtablissement VARCHAR,
    codeCommuneEtablissement VARCHAR,
    codePaysEtrangerEtablissement VARCHAR,
    libellePaysEtrangerEtablissement VARCHAR,
    identifiantAdresseEtablissement VARCHAR,
    coordonneeLambertAbscisseEtablissement VARCHAR,
    coordonneeLambertOrdonneeEtablissement VARCHAR,
    dateDebut DATE,
    enseigne1Etablissement VARCHAR,
    enseigne2Etablissement VARCHAR,
    enseigne3Etablissement VARCHAR,
    denominationUsuelleEtablissement VARCHAR,
    activitePrincipaleEtablissement VARCHAR,
    nomenclatureActivitePrincipaleEtablissement VARCHAR,
    geonames_cityid BIGINT,
    geonames_city VARCHAR,
    longitude DOUBLE PRECISION,
    latitude DOUBLE PRECISION
)
SERVER duckdb_svr OPTIONS (
    TABLE 'read_parquet("/dataset/sirene/etablissements.parquet")'
)
;


-------------------------------------------------------------------------------
-- Copy data from DuckDB to Postgres tables
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS sirene_nafrev2 CASCADE;
DROP TABLE IF EXISTS sirene_entreprises CASCADE;
DROP TABLE IF EXISTS sirene_etablissements CASCADE;

CREATE TABLE sirene_nafrev2 AS TABLE duckdb_sirene_nafrev2;
CREATE TABLE sirene_entreprises AS TABLE duckdb_sirene_entreprises;
CREATE TABLE sirene_etablissements AS TABLE duckdb_sirene_etablissements;

-------------------------------------------------------------------------------
-- Create index
-------------------------------------------------------------------------------
CREATE UNIQUE INDEX idx_sirene_etablissements_siret ON sirene_etablissements (siret);
CREATE INDEX idx_sirene_etablissements_siren ON sirene_etablissements (siren);


DROP MATERIALIZED VIEW IF EXISTS wda_sirene_etablissements;
CREATE MATERIALIZED VIEW wda_sirene_etablissements AS
SELECT
    ets.siren AS ets_siren,
    ets.nic AS ets_nic,
    ets.siret AS ets_siret,

    ets.dateCreationEtablissement AS ets_dateCreationEtablissement,
    ets.minNbEffectifsEtablissement AS ets_minNbEffectifsEtablissement,
    ets.anneeEffectifsEtablissement AS ets_anneeEffectifsEtablissement,
    ets.activitePrincipaleRegistreMetiersEtablissement AS ets_activitePrincipaleRegistreMetiersEtablissement,
    ets.dateDernierTraitementEtablissement AS ets_dateDernierTraitementEtablissement,
    ets.etablissementSiege AS ets_etablissementSiege,
    ets.numeroVoieEtablissement AS ets_numeroVoieEtablissement,
    ets.typeVoieEtablissement AS ets_typeVoieEtablissement,
    ets.libelleVoieEtablissement AS ets_libelleVoieEtablissement,
    ets.codePostalEtablissement AS ets_codePostalEtablissement,
    ets.departementEtablissement AS ets_departementEtablissement,
    ets.libelleCommuneEtablissement AS ets_libelleCommuneEtablissement,
    ets.codeCommuneEtablissement AS ets_codeCommuneEtablissement,
    ets.dateDebut AS ets_dateDebut,
    ets.enseigne1Etablissement AS ets_enseigne1Etablissement,
    ets.enseigne2Etablissement AS ets_enseigne2Etablissement,
    ets.enseigne3Etablissement AS ets_enseigne3Etablissement,
    ets.denominationUsuelleEtablissement AS ets_denominationUsuelleEtablissement,
    ets.activitePrincipaleEtablissement AS ets_activitePrincipaleEtablissement,
    ets.nomenclatureActivitePrincipaleEtablissement AS ets_nomenclatureActivitePrincipaleEtablissement,
    ets.geonames_cityid AS ets_geonames_cityid,
    ets.geonames_city AS ets_geonames_city,
    ets.longitude AS ets_longitude,
    ets.latitude AS ets_latitude,

    ens.dateCreationUniteLegale AS ens_dateCreationUniteLegale,
    ens.sigleUniteLegale AS ens_sigleUniteLegale,
    ens.identifiantAssociationUniteLegale AS ens_identifiantAssociationUniteLegale,
    ens.trancheEffectifsUniteLegale identifiantAssociationUniteLegale,
    ens.anneeEffectifsUniteLegale AS ens_anneeEffectifsUniteLegale,
    ens.dateDernierTraitementUniteLegale AS ens_dateDernierTraitementUniteLegale,
    ens.nombrePeriodesUniteLegale AS ens_nombrePeriodesUniteLegale,
    ens.categorieEntreprise AS ens_categorieEntreprise,
    ens.anneeCategorieEntreprise AS ens_anneeCategorieEntreprise,
    ens.dateDebut AS ens_dateDebut,
    ens.denominationUniteLegale AS ens_denominationUniteLegale,
    ens.denominationUsuelle1UniteLegale AS ens_denominationUsuelle1UniteLegale,
    ens.denominationUsuelle2UniteLegale AS ens_denominationUsuelle2UniteLegale,
    ens.denominationUsuelle3UniteLegale AS ens_denominationUsuelle3UniteLegale,
    ens.activitePrincipaleUniteLegale AS ens_activitePrincipaleUniteLegale,
    ens.nomenclatureActivitePrincipaleUniteLegale AS ens_nomenclatureActivitePrincipaleUniteLegale,
    ens.nicSiegeUniteLegale AS ens_nicSiegeUniteLegale,
    ens.economieSocialeSolidaireUniteLegale AS ens_economieSocialeSolidaireUniteLegale,

    nsc.section_id as insee_section_id,
    nsc.division_id as insee_division_id,
    nsc.groupe_id as insee_groupe_id,
    nsc.classe_id as insee_classe_id,
    nsc.sous_classe_id as insee_sous_classe_id,

    ns.section AS insee_section,
    nd.division AS insee_division,
    ng.groupe AS insee_groupe,
    nc.classe AS insee_classe,
    nsc.sous_classe AS insee_sous_classe

    FROM sirene_etablissements ets
    LEFT JOIN sirene_entreprises ens ON ets.siren = ens.siren
    LEFT JOIN nafrev2_sous_classes nsc ON ets.activitePrincipaleEtablissement = nsc.sous_classe_id
    LEFT JOIN nafrev2_sections ns ON nsc.section_id = ns.section_id
    LEFT JOIN nafrev2_divisions nd ON nsc.division_id = nd.division_id
    LEFT JOIN nafrev2_groupes ng ON nsc.groupe_id = ng.groupe_id
    LEFT JOIN nafrev2_classes nc ON nsc.classe_id = nc.classe_id

    WHERE ets.geonames_cityid IS NOT NULL
;


CREATE INDEX idx_sirene_siren ON wda_sirene_etablissements (ets_siren);
CREATE INDEX idx_sirene_siret ON wda_sirene_etablissements (ets_siret);
CREATE INDEX idx_sirene_activite_principale ON wda_sirene_etablissements (ets_activitePrincipaleEtablissement);

-------------------------------------------------------------------------------
-- wda informations
-------------------------------------------------------------------------------
DELETE FROM wda_scopes WHERE provider='sirene' AND dataset='wda_sirene_etablissements';
DELETE FROM wda_datasets WHERE provider='sirene' AND dataset='wda_sirene_etablissements';
DELETE FROM wda_providers WHERE provider='sirene';

INSERT INTO wda_scopes
    SELECT 'sirene' AS source, 'wda_sirene_etablissements' AS tablename, 'city' AS scope, 'wda_geonames_cities' AS tablesource, ets_geonames_city, COUNT(*)
    FROM wda_sirene_etablissements ci
    WHERE ets_geonames_cityid IS NOT NULL
    GROUP BY ets_geonames_city
;

INSERT INTO wda_datasets
    SELECT
        'sirene',
        'sirene',
        'wda_sirene_etablissements',
        'city',
        'wda_geonames_cities',
        'National Business and Establishment Identification and Registry System',
        'https://sirene.fr',
        (SELECT count(*)
FROM pg_attribute a
  JOIN pg_class t on a.attrelid = t.oid
  JOIN pg_namespace s on t.relnamespace = s.oid
WHERE a.attnum > 0
  AND NOT a.attisdropped
  AND t.relname = 'wda_sirene_etablissements'),
        COUNT(*),
        COUNT(DISTINCT ets_geonames_city)
    FROM wda_sirene_etablissements
;

INSERT INTO wda_providers
    SELECT
        'sirene',
        'System for the Identification of the Register of Establishments',
        'https://sirene.fr',
        COUNT(*),
        SUM(nb_observations)
    FROM wda_datasets wd
    WHERE provider = 'sirene';


COMMIT;
